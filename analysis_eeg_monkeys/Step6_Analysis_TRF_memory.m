%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run mTRF analysis on the EEG data from one subject
% * load preprocessed eeg data session by session for each subject
% * interpolate missing channels and remove corrupted sessions
% * average EEG data across session by melody
% * create stimulus matrix
% * run TRF by melody for differente ngrams models, separate for pitch and
% onset surprise values
% * OUTPUT: TRF weights and r coefficients for each melody and ngram models
% 
%%%%%%%%%%%%%%% Roberta Bianco Oct 2022 - Rome %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addpath(['\MATools\fieldtrip-20220321\']); ft_defaults;
% addpath(['\MATools\NoiseTools\']);       % http://audition.ens.fr/adc/NoiseTools/
% addpath(['\MATools\mTRF-Toolbox-master\mtrf']); % add the mTRF toolbox functions
% addpath(['\MATools\matlab-midi-master\src\'])

restoredefaultpath
clearvars; close all
addpath(pwd)
addpath("functions\")
cd('..\..\data\eeg\');
U = pwd;
% To get the preprocessed data
preproc_path0 = ([U 'preprocessedEEG\']); mkdir(svpth)
preproc_path = ([U 'MEMORY\']); mkdir(preproc_path); % output folder
% To get stim info
stimulus_path = ([U 'stimuli\']);
midi_path = [stimulus_path 'midiall\'];
load('Layout_Monkey_EEG.mat');


%% VIEWPOINTS: CPITCH IOI-RATIO (as in Gold 2019 JN best winning model, and Di Liberto 2020)
ngram = {'1', '2', '3', '4', '8', '12', '16', '20', '24', 'nil'};
predictor = 'StimAcoustics'; %'StimEnvelopes'
% Load acoustics
allpred = load([stimulus_path predictor]);
stim_delay = 5; % delay of the actual stimulus start relative to the start of the EEG trial
% (needed to adjust the onset times of the IDyOM model values)
% (20-4-2022) The stimulus onset is 5 s relative to the
% beep at the beginning of the .wav file
% There is also a beep at the end of the .wav file. The time from
% stimulus end to the beep *offset* is 5 s as well
skip_time = 5.2; % amount of time to exclude from the beginning and ending of the stimulus and EEG before modeling
% Model parameters
minlag = -50;
maxlag = 150;
lambdas = [0 10.^(-4:8)];
Fs = 100;

for n = 1:length(ngram)
        idyomfl = [stimulus_path '89-cpitch_onset-cpitch_ioi-ratio-nil-nil-melody-nil-10-both+-' ngram{n} '-t-nil-c-nil-t-t-x-3.dat'];

        %% Load the stimuli and create the design matrices
        disp('Loading stimulus information...');

        %%% GET IDYOM VARIABLE
        headers = {'melody.name','information.content', 'cpitch', 'entropy', 'cpitch.information.content', 'onset.information.content','cpitch.entropy', 'onset.entropy'};
        [Sall,~] = Nate_get_idyom_vars([stimulus_path idyomfl],headers,[0 1 1 1 1 1 1 1]);

        %%% GET ALLNOTES MATRIX WITH [all_id allpitches allonsets alliti allioi S Sp So];
        stim_names = {'audio01','audio02','audio03','audio04','audio05', ...
            'audio06','audio07','audio08', 'audio09','audio10',...
            'shf01','shf05','shf08','shf10'};
        midi_names = {'audio01.mid','audio02.mid','audio03.mid','audio04.mid','audio05.mid', ...
            'audio06.mid','audio07.mid','audio08.mid', 'audio09.mid','audio10.mid',...
            'shf01.mid','shf05.mid','shf08.mid','shf10.mid'};
        code_corresponding_to_midi = [101:110 111 115 118 120];
        [allinfo_all_midi] = fun_get_onset_matrix(Sall, Sall, Sall, midi_path, midi_names, code_corresponding_to_midi);

        %%% ADD ITI IOI TO TRF STIM DESCRIPTORS
        Sall.onset = allinfo_all_midi(:,3);
        Sall.ITI = allinfo_all_midi(:,4);
        Sall.IOI = allinfo_all_midi(:,5);
        Sall.Sp = allinfo_all_midi(:,7);
        Sall.So = allinfo_all_midi(:,8);
        Sall.Ep = [Sall.cpitch_entropy];
        Sall.Eo = [Sall.onset_entropy];

        stim_A = cell(length(stim_names),1);
        stim_AM = cell(length(stim_names),1);
        stim_AMshu = cell(length(stim_names),1);
        shf_idx = zeros(length(stim_names),1); % indicate if a stimulus is shuffled or not
        
        for s = 1:length(stim_names)
            % get note onsets
            if strcmp(stim_names{s}(1:3),'shf')
                shf_idx(s) = true;
            end
            idyom_stim_name = sprintf('"%s"',stim_names{s});

            % Get onsets
            stim_idx = cellfun(@(x) strcmp(x,idyom_stim_name), Sall.melody_name);
            note_onsets = Sall.onset(stim_idx);

            % Load the Acoustic descriptors
            pred_idx = find(strcmp(allpred.stim_names,[stim_names{s} '.wav']));
            spflux = allpred.spflux{pred_idx};

            % Add the other onset and idyom var idiom_v = (ONSET, 'ITI','IOI','Sp','So', 'Ep', 'Eo')
            idyom_headers = { 'ITI', 'IOI','Sp','So', 'Ep', 'Eo'};
            idyom_v = fun_TRFmake_idyom_designmatrix(Sall,idyom_stim_name,note_onsets,Fs,idyom_headers,...
                'sound_delay',stim_delay,'zero_pad_end',3*stim_delay);
            % (20-4-2022) Using 3x stim_delay should be enough time to include the
            % 5 seconds at the end of the stimulus following stimulus offset.
            % Make sure it is the sample length as the amplitude arrays
            idyom_v = idyom_v(1:length(spflux),:);

            var_to_randomise = [4 5 6 7];
            [idyom_shu] = fun_TRFmake_idyom_random(idyom_v, var_to_randomise);

            % Create the A and M design matrices
            stim_A{s} = [spflux idyom_v(:,1)]; % acustic + onset
            stim_AM{s} = [spflux idyom_v(:,1) idyom_v(:,4:7)]; % sp so
            stim_AMp{s} = [spflux idyom_v(:,1) idyom_v(:,[4 6])]; % Sp
            stim_AMo{s} = [spflux idyom_v(:,1) idyom_v(:,[5 7])]; % so
        end
        fn= sprintf('stimdesign_ngram%s.mat', ngram{n});
    save([preproc_path fn], 'stim_A', 'stim_AM', 'stim_AMp', 'stim_AMo', '-mat');
end


for sbj = 1:2
    %% Load the EEG data
    disp('Loading EEG data...');
    preproc_fl = sprintf('%s_sbj%d','alleeg_clean_icalabel', sbj);
    load([preproc_path0 preproc_fl]);

    %%% Remove session 12 and 13
    cfg = [];
    cfg.trials =  find(dataallsessions.trialinfo(:,2)~=12 & dataallsessions.trialinfo(:,2) ~= 13);
    dataallsessions = ft_selectdata(cfg, dataallsessions); % amend data to only keep good trials
    %%% Recreate missing channels
    if sbj == 1
        dataallsessions = Giac_EEG_CreateElectrodes(dataallsessions, {'Cz','CPz', 'FCz', 'Fz'}, 'Layout_Monkey_EEG', .20); % .20 is better for central electrodes
    else
        dataallsessions = Giac_EEG_CreateElectrodes(dataallsessions, {'Cz','CPz', 'F2', 'Fz'}, 'Layout_Monkey_EEG', .20); % .20 is better for central electrodes
    end

    %%% START
    alleeg = {}; stim_vals = [];
    for t = 1:length(dataallsessions.trial)
        alleeg = [alleeg; dataallsessions.trial{t}'];
    end
    stim_vals = dataallsessions.trialinfo(:,1);
    sess_vals = dataallsessions.trialinfo(:,2);
    Fs = dataallsessions.fsample;
    chan_lbls = dataallsessions.label;

    % Get the stimulus names based on the trigger values
    allstim_names = get_stims_from_triggers(stim_vals);
    stim_names = unique(allstim_names);

    eeg_bymel= fun_avgtrialsbyname(alleeg,stim_names,allstim_names);

    for n = 1:length(ngram)
        eeg = eeg_bymel;
        fn= sprintf('stimdesign_ngram%s.mat', ngram{n});
        load([preproc_path fn]);

        % Remove amount of time from the start and end of the stimulus and EEG
        if skip_time > 0
            fprintf('Removing %.1f s from start and end of the stimulus and EEG...\n',skip_time);
            for s = 1:length(stim_names)
                nidx = size(stim_A{s},1); % number of time indexes in the stimulus
                use_idx = (skip_time*Fs+1):(nidx - 4*Fs);
                stim_A{s} = stim_A{s}(use_idx,:);
                stim_AM{s} = stim_AM{s}(use_idx,:);
                stim_AMp{s} = stim_AMp{s}(use_idx,:);
                stim_AMo{s} = stim_AMo{s}(use_idx,:);
                eeg{s} = detrend(eeg{s}(use_idx,:),0); % also shift the mean to 0
                % normalize the stimulus inputs so their rms = 1
                stim_A{s} = stim_A{s}./(ones(length(use_idx),1)*rms(stim_A{s}));
                stim_AM{s} = stim_AM{s}./(ones(length(use_idx),1)*rms(stim_AM{s}));
                stim_AMp{s} = stim_AMp{s}./(ones(length(use_idx),1)*rms(stim_AMp{s}));
                stim_AMo{s} = stim_AMo{s}./(ones(length(use_idx),1)*rms(stim_AMo{s}));
            end
        end

        % Iterate over all stimuli
        orig_stim_idx = find(~shf_idx);

        % A model
        [stats_A,mdl_A] = itercvtest(stim_A,eeg,Fs,1,minlag,maxlag,lambdas);
        % AM model
        [stats_AM,mdl_AM] = itercvtest(stim_AM,eeg,Fs,1,minlag,maxlag,lambdas);
        % AMl model
        [stats_AMp,mdl_AMp] = itercvtest(stim_AMp,eeg,Fs,1,minlag,maxlag,lambdas);
        % AMshu model
        [stats_AMo,mdl_AMo] = itercvtest(stim_AMo,eeg,Fs,1,minlag,maxlag,lambdas);

        statsall_A(n, :,:) = stats_A.r_test;
        statsall_AM(n, :,:) = stats_AM.r_test;
        statsall_AMp(n, :,:) = stats_AMp.r_test;
        statsall_AMo(n, :,:) = stats_AMo.r_test;

    end

    for sn = 1:length(stim_names)
        if contains(stim_names{sn}, 'audio')
            stim_names{sn} = extractAfter(stim_names{sn}, 'audi');
        else stim_names{sn} = stim_names{sn};
        end
    end

    fn= sprintf('TRFout_sbj%d.mat',sbj);
    save([preproc_path fn], 'statsall_A', 'statsall_AM', 'statsall_AMp', 'statsall_AMo',...
        'orig_stim_idx', 'shf_idx','stim_names', '-mat');
    save([preproc_path 'chan_lbls.mat'], 'chan_lbls');
end



Matrixfinal =[];
for sbj = 1:2
    fn= sprintf('TRFout_sbj%d.mat',sbj);
    load([preproc_path fn]);
    for n = 1:length(ngram)
        idx = 1:10;
        A   = squeeze(statsall_A(n, idx,:));
        AM  = squeeze(statsall_AM(n, idx,:));
        AMp = squeeze(statsall_AMp(n, idx,:));
        AMo = squeeze(statsall_AMo(n, idx,:));

        [sorted, idxc]= sort(max(AMp), 'descend');
        idxch = idxc(1:10);
        A   = mean(A(:,idxch),2);
        AM  = mean(AM(:,idxch),2) - A;
        AMp = mean(AMp(:,idxch),2) - A;
        AMo = mean(AMo(:,idxch),2) - A;


        h = 1:10;
        rmat   = [AM; AMp; AMo];
        cond   = repmat([1 1 1 1 1 1 1 1 1 1], 1, 3);
        model  = [ones(1,length(h)),repmat(2,1,length(h)), repmat(3,1,length(h))];
        stimid = repmat(h, 1, 3) ;

        Matrix(1:length(rmat),1) = sbj;                   % subj
        Matrix(1:length(rmat),2) = rmat;                  % Pred acc difference Am / Amc - A
        Matrix(1:length(rmat),3) = cond;                  % Or or Sh Mel
        Matrix(1:length(rmat),4) = model;                 % model AM, AMp, AMo
        Matrix(1:length(rmat),5) = stimid;                % stim ID
        Matrix(1:length(rmat),6) = n;                     % ngram
        Matrixfinal = [Matrixfinal; Matrix];
    end
end

csvwrite([preproc_path 'PredAccTRFforstat_MONKEY.csv'], Matrixfinal)
