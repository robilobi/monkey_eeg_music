function [ statErp2 ] = fun_clusterBasedPermutation_SingleSubj(cond1, cond2, layout_file_name)


% Creating a FieldTrip design matrix
design = zeros(1,size(cond1.trial,2) + size(cond2.trial,2)); % for between-trials analysis, the design matrix contains only one row
design(1,1:size(cond1.trial,2)) = 1;
design(1,(size(cond1.trial,2)+1):(size(cond1.trial,2) + size(cond2.trial,2)))= 2;

% Computing the difference as a T-statistic and running an inferential test
cfg = [];
cfg.channel = {'EEG'};
%cfg.latency = [0.05 0.15];
cfg.method = 'montecarlo';
cfg.statistic = 'ft_statfun_indepsamplesT'; % independent samples T-statistic for a between-trials analysis
cfg.clusterthreshold = 'nonparametric_common';
cfg.correctm = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 3;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha = 0.05/2; % 0.05/2 because two-sided
cfg.numrandomization = 1000;

% specifies with which sensors other sensors can form clusters
cfg_neighb        = [];
cfg_neighb.method = 'triangulation'; %'distance';%'template';
cfg_neighb.layout = layout_file_name;
cfg_neighb.feedback = 'no'; % to make sure you are doing things right
cfg.neighbours    = ft_prepare_neighbours(cfg_neighb);

cfg.design = design;
cfg.ivar = 1;
statErp2 = ft_timelockstatistics(cfg,cond1, cond2);


% % Plotting stat output
% cfg = [];
% cfg.layout = layout_file_name;
% cfg.parameter = 'stat';
% cfg.maskparameter = 'mask';
% cfg.graphcolor = 'r';
% cfg.showcomment = 'no';
% cfg.showscale = 'no';
% figure;
% ft_multiplotER(cfg,statErp2);

end