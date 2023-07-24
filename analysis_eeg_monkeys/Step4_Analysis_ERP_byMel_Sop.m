%% Analysis of erp to note onsets
% RUN Step4_Analysis_ERP_CreateNoteInfo first to get the matrix with all
% notes divided by condition high vs low Sp or So (20% highest lowest S per
% melody)
% Load eeg, cut into mini epoch corresponding to the onset of each note
% Plot erp mean by high vs low surprise of picth or onset
% Run cluster based permutation test (1000) on erp averaged per session
% Compute conjunction analysis of the significant clusters for the two
% monkeys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Roberta Bianco April 2023
% addpath(['\MATools\fieldtrip-20220321\']); ft_defaults;
% addpath(['\MATools\NoiseTools\']);       % http://audition.ens.fr/adc/NoiseTools/
% addpath(['\MATools\mTRF-Toolbox-master\mtrf']); % add the mTRF toolbox functions
% addpath(['\MATools\matlab-midi-master\src\'])
% restoredefaultpath

clearvars; close all
addpath(pwd)
addpath("functions\")
cd('..\..\data\');
U = [pwd filesep];
% To get the preprocessed data
preproc_path0 = ([U 'eeg\preprocessedEEG\']);
preproc_path = ([U 'eeg\']); mkdir(preproc_path); % output folder
% To get stim info
stimulus_path = ([U 'stimuli\']);
midi_path = [stimulus_path 'midiall\'];
load('Layout_Monkey_EEG.mat');

ft_defaults;
ft_hastoolbox('brewermap', 1);

%%% VIEWPOINTS: CPITCH IOI-RATIO (as in Gold 2019 JN best winning model, and Di Liberto 2020)
idyomfl = [stimulus_path '89-cpitch_onset-cpitch_ioi-ratio-nil-nil-melody-nil-10-both+-nil-t-nil-c-nil-t-t-x-3.dat'];
midi_names = {'audio01.mid','audio02.mid','audio03.mid','audio04.mid','audio05.mid', ...
    'audio06.mid','audio07.mid','audio08.mid', 'audio09.mid','audio10.mid',...
    'shf01.mid','shf05.mid','shf08.mid','shf10.mid'};
code_corresponding_to_midi = [101:110 111 115 118 120];
midi_to_analyse = 1:14;

ploterp = 1;
recomputeerp = 0;

%%% Set graphics / color palette
cmap = colormap(flipud(brewermap(64,'PuOr')));
m = length(cmap);
cfg.ylim = [-0.55 0.55];
index = fix((0.4-cfg.ylim(1))/(cfg.ylim(2)-cfg.ylim(1))*m)+1; %A
index2 = fix((-0.4-cfg.ylim(1))/(cfg.ylim(2)-cfg.ylim(1))*m)+1; %A
RGB1 = ind2rgb(index,cmap);
RGB2 = ind2rgb(index2,cmap);

tag = 'C1C2_OriginalvsShuffled_avgbysession'; %name output file

%% LOAD NOTES VALUES AND SET CONDITION VECTOR ACCORDING TO So OR Sp
filename=([stimulus_path 'Noteinfo_CondByPitchOnset_noCtrl.mat']);
load(filename);

if recomputeerp == 1
    %% EXTRACT MINIEPOCHS LOCKED TO ONSET PER CONDITION
    for sbj =1:2
        svfnm = sprintf('%s_sbj%d','alleeg_clean_icalabel', sbj);
        file = [preproc_path0 svfnm];
        [data_out] = fun_load_epoch_eeg(file, allinfo, midi_names,code_corresponding_to_midi, midi_to_analyse,midi_path, sbj);

        %%% Select notes high vs low S
        cfg =[];
        cfg.trials = data_out.trialinfo(:,5) == 1;  % LOW IC
        datac1 = ft_selectdata(cfg,data_out);
        cfg =[];
        cfg.trials = data_out.trialinfo(:,5) == 2;  % HIGH IC
        datac2 = ft_selectdata(cfg,data_out);

        COND1{sbj}=datac1;
        COND2{sbj}=datac2;
        clear datac1 datac2 data_out
    end

    %%  SELECT HIGH VS LOW SEPARATELY FOR Or vs Sh
    for sbj = 1:2
        datac1 = COND1{sbj}; datac2=COND2{sbj};
        cfg =[];
        cfg.trials =ismember( datac1.trialinfo(:,2),[101:110]);%   cfg.trials =ismember( datac1.trialinfo(:,1),1:10);
        orc1{sbj} = ft_selectdata(cfg,datac1);
        cfg =[];
        cfg.trials =ismember( datac2.trialinfo(:,2),[101:110]);%   cfg.trials =ismember( datac1.trialinfo(:,1),1:10);
        orc2{sbj} = ft_selectdata(cfg,datac2);
        cfg =[];
        cfg.trials = ismember(datac1.trialinfo(:,2), [111 115 118 120]);
        shc1{sbj} = ft_selectdata(cfg,datac1);
        cfg =[];
        cfg.trials = ismember(datac2.trialinfo(:,2), [111 115 118 120]);
        shc2{sbj} = ft_selectdata(cfg,datac2);
    end
    clear COND1 COND2

    %% AVERAGE TRIAL BY SESSION
    for sbj =1:2 %%%% ORIGNAL high vs low S
        [out] = fun_averagebysession(orc1{sbj});
        orc1_avg{sbj} =out;
        [out] = fun_averagebysession(orc2{sbj});
        orc2_avg{sbj} =out;
    end
    for sbj =1:2 %%%% SHUFFLED  high vs low S
        [out] = fun_averagebysession(shc1{sbj});
        shc1_avg{sbj} =out;
        [out] = fun_averagebysession(shc2{sbj});
        shc2_avg{sbj} =out;
    end

    %% RUN CLUSER BASED PERMUTATION STATS
    rng(1);
    for sbj =1:2
        [ statErpOr ] = fun_clusterBasedPermutation_SingleSubj(orc1_avg{sbj}, orc2_avg{sbj}, 'Layout_Monkey_EEG');
        filename=([preproc_path 'ClstPerm_image_Or_sbj' num2str(sbj)]);
        fun_clusterBasedPermutation_Plot(statErpOr,filename, 'C1vsC2', 'images','F_value', 'Layout_Monkey_EEG.mat');

        [ statErpSh ] = fun_clusterBasedPermutation_SingleSubj(shc1_avg{sbj}, shc2_avg{sbj}, 'Layout_Monkey_EEG');
        filename=([preproc_path 'ClstPerm_image_Sh_sbj' num2str(sbj)]);
        fun_clusterBasedPermutation_Plot(statErpSh,filename, 'C1vsC2', 'images','F_value', 'Layout_Monkey_EEG.mat');

        stats_or{sbj} = statErpOr;% SAVE STATS FOR BOTH SUBJ
        stats_sh{sbj} = statErpSh;
    end

    %% SAVE DATA AND STATS
    filename=([preproc_path 'eeg_erp_ClstStats_' tag]);
    save(filename, 'stats_sh', 'stats_or', '-v7.3');
    filename=([preproc_path 'eeg_erp_' tag]);
    save(filename, 'orc1_avg', 'orc2_avg','shc1_avg', 'shc2_avg','-v7.3');

else
    filename=([preproc_path 'eeg_erp_ClstStats_' tag]);
    load(filename);
    filename=([preproc_path 'eeg_erp_' tag]);
    load(filename);
end


%% DISPLAY CONJUNCTION
filename=([preproc_path 'ClstPerm_2D_CONJ_original']);
[values_or, order_chan] = fun_conjunction(stats_or, filename);
display(['CLUSTER VALUES ORIGINAL MEL :' num2str(unique(values_or)')]);
filename=([preproc_path 'ClstPerm_2D_CONJ_shuffled' ]);
[values_sh, order_chan] = fun_conjunction(stats_sh, filename);
display(['CLUSTER VALUES SHUFFLED MEL :' num2str(unique(values_sh)')]);

%% PLOT ERPS
if ploterp
    for sbj = 1:2
        cfg =[];
        cfg.preproc.demean = 'no';
        cfg.demean          = 'no';
        orc1avg = ft_timelockanalysis(cfg, orc1_avg{sbj});
        orc2avg = ft_timelockanalysis(cfg, orc2_avg{sbj});
        shc1avg = ft_timelockanalysis(cfg, shc1_avg{sbj});
        shc2avg = ft_timelockanalysis(cfg, shc2_avg{sbj});
        statErpOr= stats_or{sbj} ;
        statErpSh = stats_sh{sbj};

        %Topo
        cfg = [];
        cfg.operation = 'subtract';
        cfg.parameter = 'trial';
        avg_diffORt = ft_math(cfg,orc2_avg{sbj},orc2_avg{sbj});
        avg_diffSHt = ft_math(cfg,shc2_avg{sbj},shc1_avg{sbj});
        avg_diffOR = ft_timelockanalysis(cfg, avg_diffORt);
        avg_diffSH = ft_timelockanalysis(cfg, avg_diffSHt);

        h=figure;clf
        h.Position = [100 100 600 600];
        cfg = [];
        cfg.channel = {'FCz'};
        cfg.linewidth = 2;
        cfg.comment = '';
        cfg.figure = 'gca';
        cfg.ylim = [-0.3 0.48];
        cfg.xlim = [-0.05 0.150];
        cfg.graphcolor =[RGB2; RGB1];
        yl = cfg.ylim;
        subplot(3,2,1); ft_singleplotER(cfg,orc1avg, orc2avg);title('Original');
        signtime = statErpOr.time(find(mean(statErpOr.mask,1)~=0));
        if ~isempty(signtime); for i = 1:length(signtime)
                significance = [signtime(i) signtime(i) signtime(i)+0.01 signtime(i)+0.01];
                p = patch(significance(1,:),[yl(1) yl(1)+0.05 yl(1)+0.05 yl(1)], 'k');
                set(p, 'FaceAlpha',0.2, 'EdgeColor','none');end; end

        subplot(3,2,2); ft_singleplotER(cfg,shc1avg, shc2avg);title('Shuffled')
        signtime = statErpSh.time(find(mean(statErpSh.mask,1)~=0));
        if ~isempty(signtime); for i = 1:length(signtime)
                significance = [signtime(i) signtime(i) signtime(i)+0.01 signtime(i)+0.01];
                p = patch(significance(1,:),[yl(1) yl(1)+0.05 yl(1)+0.05 yl(1)], 'k');
                set(p, 'FaceAlpha',0.2, 'EdgeColor','none');end;end
        legend({'Low S', 'High S'}, 'Location','best')

        %Topo
        cfg = [];
        cfg.operation = 'subtract';
        cfg.parameter = 'avg';
        avg_diffOR = ft_math(cfg,orc2avg,orc1avg);
        avg_diffSH = ft_math(cfg,shc2avg,shc1avg);

        cfg = [];
        cfg.layout = 'Layout_Monkey_EEG';
        cfg.marker = 'off';
        cfg.style = 'straight';
        cfg.figure = 'gca';
        cfg.colorbar = 'yes';
        cfg.zlim = [-0.15 0.15];
        if sbj == 1
            cfg.xlim = [0.06 0.08];
        else
            cfg.xlim = [0.03 0.04];
        end
        cfg.comment = ['s ' num2str(cfg.xlim)];
        subplot(3,2,3); ft_topoplotER(cfg,avg_diffOR);title('OR W1: H > L ');
        subplot(3,2,4); ft_topoplotER(cfg,avg_diffSH);title('SH W1: H > L ');
        cfg.comment = 'W0:.0 .01 ';

        if sbj == 1
            cfg.xlim = [-0.01 0.010];
        else
            cfg.xlim = [0 0.010];
        end
        subplot(3,2,5); ft_topoplotER(cfg,avg_diffOR);title('OR W0: H > L');
        subplot(3,2,6); ft_topoplotER(cfg,avg_diffSH);title('SH W0: H > L ');
        c = colorbar;
        c.LineWidth = 1;
        colormap(flipud(brewermap(64,'PuOr')));
        filename=([preproc_path 'ERPANDTOPO_sbj' num2str(sbj)]);
        saveas(gcf, [filename '.png']);
        print([filename '.pdf'],'-dpdf','-bestfit')
        print([filename '.eps'],'-depsc');

    end
end


