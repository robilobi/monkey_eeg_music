%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT mTRF r coef for each subject
% * INPUT: TRFout_all_sbj?.mat'
% * OUTPUT: 'PredAccTRFforstat.csv' (for stats in R script); Plots
%%%%%%%%%%%%%%% Roberta Bianco Oct 2022 - Rome %%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all
U = 'C:\Users\robianco\OneDrive - Fondazione Istituto Italiano Tecnologia';
addpath([U '\MATools\fieldtrip-20220321\']); ft_defaults;
preproc_path = [U '\BACHMK\DATAVERSE\Monkeys\eeg\PITCHONSET\']; mkdir(preproc_path);

selectchn = 1;
sessions = {'all'};
Matrixfinal =[];


a_lbl = {'SpFlux'};
am_lbl = {'SpFlux','Sp','So'};
amp_lbl = {'SpFlux','Sp'};
amo_lbl = {'SpFlux','So'};


for sess = 1:length(sessions)
    for sbj = 1:2
        session = sessions{sess};
        load([preproc_path 'chan_lbls.mat']);
        load([preproc_path 'TRFout_' session '_sbj' num2str(sbj) '.mat']);

        % PLOT ACC BY ORIGINAL AND SHF CONDITION
        shf_stim_idx = find(shf_idx);
        r_ori_A = statsall_A.r_test(orig_stim_idx, :);
        r_ori_AM = statsall_AM.r_test(orig_stim_idx, :);
        r_ori_AMp = statsall_AMp.r_test(orig_stim_idx, :);
        r_ori_AMo = statsall_AMo.r_test(orig_stim_idx, :);

        r_shf_A = statsall_A.r_test(shf_stim_idx, :);
        r_shf_AM = statsall_AM.r_test(shf_stim_idx, :);
        r_shf_AMp = statsall_AMp.r_test(shf_stim_idx, :);
        r_shf_AMo = statsall_AMo.r_test(shf_stim_idx, :);

        %%% SELECT CHN WITH MAX R ACROSS A MODEL
        if selectchn
            [sorted, idx]= sort(max(r_ori_A), 'descend');
            idxch = idx(1:10);
        else
            idxch = 1:length(chan_lbls);
        end
        chan_lbls(idxch)


        %% PLOT A AND AM MODEL WEIGHTS
        % AVERAGE normalised TRF models across 14 melodies
        time = mdl_A{1}.t;
        avgmodelA = mTRFmodelAvgRB(mdl_A,1);
        avgmodelAM = mTRFmodelAvgRB(mdl_AM,1);
        avgmodelAMp = mTRFmodelAvgRB(mdl_AMp,1);
        avgmodelAMo = mTRFmodelAvgRB(mdl_AMo,1);

        chan_to_plot = idxch;

        pred = [1, 3:4]; % find max in the model of interest per monkey
        w(1:3,:) = mean(avgmodelAM.w(pred,:,chan_to_plot),3);
        limits = [min(min(w)) max(max(w))];
        figure, set(gcf,'Position',[100 100 1100 400]);

        subplot(1,4,1);hold on
        w = zeros(length(a_lbl),length(time));
        w(1,:) = mean(avgmodelA.w(1,:,chan_to_plot),3);xlim([-50 150]);ylim(limits);
        %         imagesc(time,1:size(w,1),w, limits);yticks(1:5); yticklabels(a_lbl);
        %clim([-max(abs(w),[],'all') max(abs(w),[],'all')]);
        %colorbar('SouthOutside');colormap(flipud(brewermap(64,'PuOr')));
        for i = 1:size(w,1); plot(time,w(i,:));end
        xlabel('Lags (ms)');ylabel('Model weight');legend(a_lbl);
        title(sprintf('Model A, Mk %d',sbj));

        subplot(1,4,2);hold on
        w = zeros(length(am_lbl),length(time));
        w(1:3,:) = mean(avgmodelAM.w(pred,:,chan_to_plot),3);xlim([-50 150]);ylim(limits);
        %         imagesc(time,1:size(w,1),w, limits);yticks(1:5); yticklabels(am_lbl);
        %clim([-max(abs(w),[],'all') max(abs(w),[],'all')]);
        %colorbar('SouthOutside');colormap(flipud(brewermap(64,'PuOr')));
        for i = 1:size(w,1); plot(time,w(i,:));end
        xlabel('Lags (ms)');ylabel('Model weight');legend(am_lbl);
        title(sprintf('Model AM, Mk %d',sbj));

        pred = [1, 3]; %
        subplot(1,4,3);hold on
        w = zeros(length(amp_lbl),length(time));
        w(1:2,:) = mean(avgmodelAMp.w(pred,:,chan_to_plot),3);xlim([-50 150]);ylim(limits);
        %         imagesc(time,1:size(w,1),w, limits);yticks(1:5); yticklabels(amshu_lbl);
        %clim([-max(abs(w),[],'all') max(abs(w),[],'all')]);
        %colorbar('SouthOutside');colormap(flipud(brewermap(64,'PuOr')));
        for i = 1:size(w,1); plot(time,w(i,:));end
        xlabel('Lags (ms)');ylabel('Model weight');legend(amp_lbl);
        title(sprintf('Model AMp, Mk %d',sbj));


        subplot(1,4,4);hold on
        w = zeros(length(amo_lbl),length(time));
        w(1:2,:) = mean(avgmodelAMo.w(pred,:,chan_to_plot),3);xlim([-50 150]);ylim(limits);
        %         imagesc(time,1:size(w,1),w, limits);yticks(1:5); yticklabels(amshu_lbl);
        %clim([-max(abs(w),[],'all') max(abs(w),[],'all')]);
        %colorbar('SouthOutside');colormap(flipud(brewermap(64,'PuOr')));
        for i = 1:size(w,1); plot(time,w(i,:));end
        xlabel('Lags (ms)');ylabel('Model weight');legend(amo_lbl);
        title(sprintf('Model AMo, Mk %d',sbj));

        fn = sprintf('MdlsImage_%s_sbj%d_bestchan',session,sbj);
        saveas(gcf,[preproc_path fn '.png']);
        saveas(gcf,[preproc_path fn '.fig']);
        print([preproc_path fn '.pdf'],'-dpdf','-bestfit')


        %%  PLOT TOPOGRAPHIES OF AM-A AND AMc-A MODELS
        cfg = [];
        cfg.layout = 'Layout_Monkey_EEG.mat';
        cfg.baselinetype = 'absolute';
        layout = ft_prepare_layout(cfg);
        nchan = size(chan_lbls,1);

        %%% AM - A model
        index = cellfun(@(a) strmatch(a,layout.label),chan_lbls,'uniform',false);
        idxchn = cell2mat(index);
        diffO = r_ori_AM - r_ori_A;
        diffS = r_shf_AM - r_shf_A;
        climd = min(min([mean(diffO); mean(diffS)]));
        climu = max(max([mean(diffO); mean(diffS)])) ;
        figure; set(gcf,'Position',[100 100 860 600]);
        % Original and Shuffled  stimuli
        subplot(2,1,1)
        ft_plot_topo(layout.pos(idxchn,1),layout.pos(idxchn,2),mean(diffO),...
            'mask',layout.mask,'outline',layout.outline,'interplim','mask', 'clim',[climd climu]);
        set(gca,'FontSize',12);axis off; axis('square'); colorbar('SouthOutside');
        %colormap(flipud(brewermap(64,'RdBu')));
        title(sprintf('Diff AM - A, Orig stimuli - %s, Mk %d',session,sbj));
        subplot(2,1,2)
        ft_plot_topo(layout.pos(idxchn,1),layout.pos(idxchn,2),mean(diffS),...
            'mask',layout.mask,'outline',layout.outline,'interplim','mask', 'clim',[climd climu]);
        set(gca,'FontSize',12);axis off; axis('square'); colorbar('SouthOutside'); %colormap(flipud(brewermap(64,'RdBu')));
        title(sprintf('Diff AM - A, Shuffled stimuli - %s, Mk %d',session,sbj));
        fn = sprintf('/RTopo_AM-A_%s_sbj%d',session,sbj);
        saveas(gcf,[preproc_path fn '.png']);
        print([preproc_path fn '.pdf'],'-dpdf','-bestfit')


        %%% AMp - A model
        diffO = r_ori_AMp - r_ori_A;
        diffS = r_shf_AMp - r_shf_A;
        figure; set(gcf,'Position',[100 100 860 600]);
        % Original and Shuffled  stimuli
        subplot(2,1,1)
        ft_plot_topo(layout.pos(idxchn,1),layout.pos(idxchn,2),mean(diffO),...
            'mask',layout.mask,'outline',layout.outline,'interplim','mask', 'clim',[climd climu]);
        set(gca,'FontSize',12);axis off; axis('square'); colorbar('SouthOutside'); %colormap(flipud(brewermap(64,'RdBu')));
        title(sprintf('Diff AMp - A, Orig stimuli - %s, Mk %d',session,sbj));
        subplot(2,1,2)
        ft_plot_topo(layout.pos(idxchn,1),layout.pos(idxchn,2),mean(diffS),...
            'mask',layout.mask,'outline',layout.outline,'interplim','mask', 'clim',[climd climu]);
        set(gca,'FontSize',12);axis off; axis('square'); colorbar('SouthOutside'); %colormap(flipud(brewermap(64,'RdBu')));
        title(sprintf('Diff AMp - A, Shuffled stimuli - %s, Mk %d',session,sbj));
        fn = sprintf('/RTopo_AMpitch-A_%s_sbj%d',session,sbj);
        saveas(gcf,[preproc_path fn '.png']);
        print([preproc_path fn '.pdf'],'-dpdf','-bestfit')


        %%% AMo - A model
        diffO = r_ori_AMo - r_ori_A;
        diffS = r_shf_AMo - r_shf_A;
        figure; set(gcf,'Position',[100 100 860 600]);
        % Original and Shuffled  stimuli
        subplot(2,1,1)
        ft_plot_topo(layout.pos(idxchn,1),layout.pos(idxchn,2),mean(diffO),...
            'mask',layout.mask,'outline',layout.outline,'interplim','mask', 'clim',[climd climu]);
        set(gca,'FontSize',12);axis off; axis('square'); colorbar('SouthOutside'); %colormap(flipud(brewermap(64,'RdBu')));
        title(sprintf('Diff AMo - A, Orig stimuli - %s, Mk %d',session,sbj));
        subplot(2,1,2)
        ft_plot_topo(layout.pos(idxchn,1),layout.pos(idxchn,2),mean(diffS),...
            'mask',layout.mask,'outline',layout.outline,'interplim','mask', 'clim',[climd climu]);
        set(gca,'FontSize',12);axis off; axis('square'); colorbar('SouthOutside'); %colormap(flipud(brewermap(64,'RdBu')));
        title(sprintf('Diff AMo - A, Shuffled stimuli - %s, Mk %d',session,sbj));
        fn = sprintf('/RTopo_AMonset-A_%s_sbj%d',session,sbj);
        saveas(gcf,[preproc_path fn '.png']);
        print([preproc_path fn '.pdf'],'-dpdf','-bestfit')


        %% EXTRACT PRED ACCURACY DIFFERENCE
        AO= mean(r_ori_A(:,idxch),2);
        AS= mean(r_shf_A(:,idxch),2);
        A = [AO; AS; AO; AS; AO; AS];

        AMO = mean(r_ori_AM(:,idxch),2) - AO;
        AMS = mean(r_shf_AM(:,idxch),2) - AS;

        AMpO = mean(r_ori_AMp(:,idxch),2) -AO;
        AMpS = mean(r_shf_AMp(:,idxch),2) -AS;


        AMoO = mean(r_ori_AMo(:,idxch),2) -AO;
        AMoS = mean(r_shf_AMo(:,idxch),2) -AS;


        namesO = stim_names(orig_stim_idx);
        namesS = stim_names(logical(shf_idx));

        rmat = [AMO; AMS; AMpO; AMpS; AMoO; AMoS;];
        names = [namesO; namesS];
        cond = repmat([1 1 1 1 1 1 1 1 1 1 2 2 2 2], 1, 3);
        model = [ones(1,14),repmat(2,1,14), repmat(3,1,14)];
        [g, h]=ismember(names, stim_names);
        stimid =repmat(h, 3, 1) ;

        Matrix(1:42,1) = sbj;                   %subj
        Matrix(1:42,2) = rmat;                  % Pred acc difference Am / Amc - A
        Matrix(1:42,3) = cond;                  %Or or Sh Mel
        Matrix(1:42,4) = model;                 %model AM, AMp, AMo
        Matrix(1:42,5) = stimid;                %stim ID
        Matrix(1:42,6) = A;                    % Pred Acc A model
        Matrixfinal = [Matrixfinal; Matrix];

    end
    csvwrite([preproc_path 'PredAccTRFforstat' session '.csv'], Matrixfinal)

end
