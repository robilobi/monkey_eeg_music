%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preprocessing script for extracting  Monkey EEG data from BDF files
% * Each BDF file contains two subjects with 29 channels each
% * Stimulus labels are 101-118 (101-110 are original stimuli, 111-115-118-120 are
% shuffled/randomized)
% * The same 2 subjects run through 26 sessions with identical stimuli
% presented in randomised order
% - Preprocess the BDF file:
% filter, epoch, downsample, split EEG data into two subjects
% - Preprocess each subject, each session separately:
% ASR on concatenated epochs, interpolate bad channels, remove bad trials,
% - Preprocess each subject merged sessions:
% ICA to remove eye components, recreate missing chanels, Rereference CAR, PCA to extract ERP PC.
% - Save preprocessed data separately for the two subjects
%%%%%%%%%%%%%%% Roberta Bianco Oct 2022 - Rome %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addpath([ '\MATools\fieldtrip-20220321\']); ft_defaults;
% addpath(['\MATools\NoiseTools\']);       % http://audition.ens.fr/adc/NoiseTools/

clearvars; close all
addpath(pwd)
addpath("functions\")
cd('..\..\data\');
U = [pwd filesep];
% To get raw data
eegpth = ([U 'eeg\rawEEG\']);
% To store the preprocessed data
svpth = ([U 'eeg\preprocessedEEG\']); mkdir(svpth)
% To get stim info
stimulus_path = ([U 'stimuli\']);
midi_path = [stimulus_path 'midiall\'];
load('Layout_Monkey_EEG.mat');


desFs = 500;        % sampling rate of the EEG after downsampling
desFs2 = 100;       % sampling rate of the EEG after downsampling
getsubstrALL       % EXCLUDE Sess 23; cell array called substr containing the names of the BDF files
subjects = [1 2];
prepro.pca         = 0;
sessionstoinclude  = [1:11 13:25];
labels = {'ASR5-IClabel' };

for sbj =subjects
    for rep = 1:length(sessionstoinclude)
        svfnm = sprintf('%s_sess%d','dualeeg', sessionstoinclude(rep));
        load([svpth svfnm]);
        disp(['... CLEANING SUBJ ' num2str(sbj)]);

        %%% SELECT MK SPECIFIC CHANNELS
        if sbj == 1
            %'CPz', 'Cz', '1-Fz', 1-FCz', MIGUEL (camera)
            eeglab_template = 'eeglab_template_mk1.mat';
            channel              = {'1-O2','1-Oz','1-O1','1-PO4','1-POz','1-PO3','1-P4','1-P2','1-P1','1-P3','1-CP4','1-CP2','1-CP1','1-CP3','1-FC6','1-FC4','1-FC2','1-FC1','1-FC3','1-FC5','1-F2','1-F1','1-AF4','1-AF3'};
        elseif sbj == 2
            %'CPz', 'Cz', '2-Fz','2-F2' Tullio (camera)
            eeglab_template = 'eeglab_template_mk2.mat';
            channel              = {'2-O2','2-Oz','2-O1','2-PO4','2-POz','2-PO3','2-P4','2-P2','2-P1','2-P3','2-CP4','2-CP2','2-CP1','2-CP3','2-FC6','2-FC4','2-FC2','2-FCz','2-FC1','2-FC3','2-FC5','2-F1','2-AF4','2-AF3'};
        end
        cfg.channel = channel;            % rename channels for each subject
        data = ft_selectdata(cfg, dualdata);
        for i=1:length(cfg.channel)
            data.label{i,1} = data.label{i,1}(3:end);
        end

        %%% DETECT NOISY CHANNELS
        out_ch_noisy_toremove = [];
        remained_out_ch_noisy = [];
        [ out_ch_noisy ] = Giac_EEG_CatchNoisyElectrodes( data, 'EEG', 2.75, 'recursive');

        %%% KEEP ANTERIOR FRONTAL FOR EYE SIGNAL
        out_ch_noisy_toremove = out_ch_noisy(~ismember(out_ch_noisy, {'AF3', 'AF4'}));

        %%% REREFERENCE ONLY WITH GOOD CHANNELS
        ch_for_reref = data.label(~ismember(data.label, out_ch_noisy)); %% Remove bad channels
        cfg                      = [];
        cfg.channel              = {'EEG'};
        cfg.reref                = 'yes';
        cfg.refchannel           = ch_for_reref; %% Reref only using good channels
        data_reref               = ft_preprocessing(cfg,data);
        [ data_noBadChn ]        = Giac_removeChannels( data_reref, out_ch_noisy_toremove );

        %%% ASR
        ref_maxbadchannels = 0.075;
        cutoff             = 5;
        %%% eeg_asr = RFT_clean_asr_combined_trials_ftstruct(data_noBadChn,'eeglab_template_mk', 'Layout_Monkey_EEG', 3, [], 0.05);
        addpath([U '\MATools\clean_rawdata2.7']);
        [eeg_asr , asr_ref_section, asr_eigen_ref_time, asr_eigen_ref_topo, percsign]  = RFT_clean_asr_combined_trials_ftstruct(data_noBadChn,'eeglab_template_mk.mat',cutoff,[],ref_maxbadchannels);
        rmpath([U '\MATools\clean_rawdata2.7']);
        asrretainedsignal(rep) =100*(mean(percsign));

        %             %%% Visualize ASR reference section
        %              RFT_EEG_Visualise( asr_ref_section , {'all'}, [-30 30], 'Layout_Monkey_EEG');
        %             %%% Visualize time curves of ASR PCs in reference section
        %              RFT_EEG_Visualise( asr_eigen_ref_time , {'all'}, [-20 20], 'Layout_Monkey_EEG');
        %             %%% Visualize topographies of ASR PCs in reference section
        %             figure;
        %             cfg                 = [];
        %             cfg.component       = [1:15];       % specify how many PCs to be plotted
        %             cfg.layout          = 'Layout_Monkey_EEG';
        %             cfg.comment         = 'no';
        %             RFT_topoplotIC(cfg, asr_eigen_ref_topo);
        %             sgtitle(['Animal ' num2str(sbj) ', ' labels{param}]);
        %             filename=([svpth 'ASR_diffParam_Comp_sbj' num2str(sbj) '_sess' num2str(sessionstoinclude) ',' labels{param}]);
        %             saveas(gcf, [filename '.png']);


        %%% ICA
        addpath([U '\MATools\eeglab2022.1\' ]);
        pcaDim = length(eeg_asr.label)-1; % reduce rank by 1 because of Reref
        [eeg_asr_ica, rejectedcmp] = RFT_IClabel(eeg_asr,eeglab_template,[0 0;0 0; 0.1 1; 0 0; 0 0; 0 0; 0 0], pcaDim);
        rmpath(genpath([U '\MATools\eeglab2022.1\' ]));

        topofilename=([svpth 'ICAComp_sbj' num2str(sbj) '_sess' num2str(sessionstoinclude(rep)) ',' labels{1}]);
        saveas(gcf, [topofilename '.png']);
        close all

        %         RFT_EEG_Visualise(  data , {'all'}, [-20 20], 'Layout_Monkey_EEG')
        %         RFT_EEG_Visualise(  data_noBadChn , {'all'}, [-20 20], 'Layout_Monkey_EEG')
        %         RFT_EEG_Visualise(  eeg_asr , {'all'}, [-20 20], 'Layout_Monkey_EEG')
        %         RFT_EEG_Visualise(  eeg_asr_ica , {'all'}, [-20 20], 'Layout_Monkey_EEG')

        data_clean = eeg_asr_ica;
        %%% CHANNEL INTERPOLATION
        if ~isempty(out_ch_noisy_toremove)
            cfg =[];
            load('Layout_Monkey_EEG');
            cfg.layout          = lay;
            layout              = ft_prepare_layout(cfg);
            cfg                 = [];
            cfg.layout          = layout;
            cfg.method          = 'distance'; % for prepare_neigh
            cfg.neighbourdist   = .25;         % results in avg 5 channels
            cfg.neighbours      = ft_prepare_neighbours(cfg);
            cfg.badchannel      = out_ch_noisy_toremove'; %data.label(ChanInterpol);
            cfg.method          = 'nearest';
            data_clean    = ft_channelrepair(cfg, eeg_asr_ica);

            %%% DETECT NOISY CHANNELS DESPITE CLEANINIG
            [ remained_out_ch_noisy ] = Giac_EEG_CatchNoisyElectrodes( data_clean, 'EEG', 2.75, 'recursive');

            %%% CHANNEL INTERPOLATION
            if ~isempty(remained_out_ch_noisy)
                layout              = ft_prepare_layout(cfg);
                cfg                 = [];
                cfg.layout          = layout;
                cfg.method          = 'distance'; % for prepare_neigh
                cfg.neighbourdist   = .25;         % results in avg 5 channels
                cfg.neighbours      = ft_prepare_neighbours(cfg);
                cfg.badchannel      = remained_out_ch_noisy'; %data.label(ChanInterpol);
                cfg.method          = 'nearest';
                data_clean          = ft_channelrepair(cfg, data_clean);
            end

            %%% IF THERE ARE STILLNaN / MISSING CHANNELS INTERPOLATE THEM
            while find(isnan(data_clean.trial{1}(:,:))) >0
                missing = data_clean.label(find(isnan(data_clean.trial{1}(:,1))))';
                cfg.missingchannel  = missing;
                cfg.senstype        = 'eeg';
                cfg.method          = 'average';
                data_clean   = ft_channelrepair(cfg, data_clean);
            end
        end
        data_clean.trialinfo(:,2) = rep;

        %%% DOWNSAMPLE AT 100 HZ (ENOUGH FOR ERP AND TRF ANALYSIS)
        cfg                      = [];
        cfg.resamplefs           = desFs2;
        cfg.detrend              = 'no';
        cfg.demean               = 'no';
        [data_clean]             = ft_resampledata(cfg, data_clean);

        %%% STORE SESSIONS
        all_eeg_sessions{rep} = data_clean;
        all_eeg_noisyChn{rep} =  [out_ch_noisy_toremove(:)' remained_out_ch_noisy(:)'];
        all_ica_rejectedcmp{rep} = rejectedcmp;

    end

    %%% SAVE INTERPOLATED CHANNELS AND REJ ICA CMP
    filename=([svpth 'all_eeg_noisyChn_sbj' num2str(sbj) '_' labels{1}]);
    save(filename, 'all_eeg_noisyChn');

    filename=([svpth 'all_eeg_rejCmpICA_sbj' num2str(sbj) '_' labels{1}]);
    save(filename, 'all_ica_rejectedcmp' );

    close all

    %%% PLOT ASR signal retained by session
    [value, ss]=sort(asrretainedsignal);
    bar(ss, value); ylabel('% signal kept as reference'); xlabel('session')
    filename=([svpth 'ASR_cleansign_sbj' num2str(sbj) '_Nsess' num2str(numel(sessionstoinclude)) '_' labels{1}]);
    saveas(gcf, [filename '.png']);

    %%% APPEND SESSIONS
    data         = cell(1,length(sessionstoinclude));
    cfg               = [];
    dataallsessions    = ft_appenddata(cfg,all_eeg_sessions{:});

    %%% Find bad trials (2SD from mean) ## use noisetools
    mateeg = nt_trial2mat(dataallsessions.trial);
    mateeg(isnan(mateeg)) = 0;
    good_trials=nt_find_outlier_trials(mateeg, 2); %  nt_find_outlier_trials requires input structure time * channels * trials)
    alltrials = 1:size(mateeg, 3);
    bad_trials =alltrials(~ismember(alltrials, good_trials));

    %%% Remove bad trials
    cfg = [];
    cfg.trials = good_trials;
    dataallsessions = ft_selectdata(cfg, dataallsessions); % amend data to only keep good trials

    [ nan_trials ] = Giac_findNanTrials( dataallsessions, 'OnlyOne' );

    %%% Check ERP Extract notes onsets
    midi_names = {'audio01.mid','audio02.mid','audio03.mid','audio04.mid','audio05.mid','audio06.mid','audio07.mid','audio08.mid', ...
        'audio09.mid','audio10.mid', 'shf01.mid','shf05.mid','shf08.mid','shf10.mid'};
    code_corresponding_to_midi = [101:110 111 115 118 120];
    baseline_dur = 5; % IN S
    new_sampling = dataallsessions.fsample; % in Hz
    n_offsets    = [.100 .250]; % in s
    [data_out] = RFT_MiniTrialMaker(dataallsessions,midi_names,code_corresponding_to_midi,midi_path,baseline_dur,new_sampling,n_offsets);
    %%% Baseline correct
    cfg                 = [];
    cfg.baselinewindow  = [-.02 0];
    cfg.demean = 'yes';
    data_out_bc      = ft_preprocessing(cfg,data_out);
    %%% Timelock analysis
    cfg =[];
    avg = ft_timelockanalysis(cfg, data_out_bc);
    stderr = sqrt(avg.var) / sqrt(avg.dof(1,1));
    avg.stderr=stderr;
    avgs_erps=avg;
    %%% Plot Erps
    figure;
    cfg =[];
    cfg.layout='Layout_Monkey_EEG';
    cfg.channel = {'FC2'};
    cfg.showlegend = 'yes';
    RFT_singleplotER(cfg,avgs_erps);    %ylim([-0.2 0.2]);
    legend(labels, 'Location','best'); title(['Animal ' num2str(sbj)]);
    filename=([svpth 'ERP_sbj' num2str(sbj) '_allsessions']);
    legend(labels, 'Location','best'); title(['Animal ' num2str(sbj)]);
    saveas(gcf, [filename '.png']);


    RFT_EEG_Visualise(  dataallsessions , {'all'}, [-20 20], 'Layout_Monkey_EEG')


    %% Save clean data
    svfnm = sprintf('%s_sbj%d','alleeg_clean_icalabel', sbj);
    save([svpth svfnm],'dataallsessions', 'good_trials',  '-v7.3');
end

