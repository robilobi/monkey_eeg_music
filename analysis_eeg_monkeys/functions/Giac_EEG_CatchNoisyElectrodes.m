function [ ele_names_all ] = Giac_EEG_CatchNoisyElectrodes( data, channels_of_interest, std_nr, mode )
%
% This function goes through all trials (FT structure) and identifies
% electrode that are likely to be noisy-faulty etc. 
% mode defines whether the algorithm works in a 'recursive' or 'single'
% based mode 
%% Giacomo Novembre -- modified Roberta Bianco ( Oct 2022)

%% Select only channels of interest
cfg         = [];
cfg.channel = [channels_of_interest];
data        = ft_selectdata(cfg,data);

for cc=1:length(data.label)
display(['GIAC: starting with electrodes: ' mat2str(data.label{cc})]);
end

switch mode
    case 'recursive'
        
        Go_recursive  = 'yes';
        counter_recur = 0;
        ele_names_all = [];

        while strcmp(Go_recursive,'yes') == 1

            % Now turn 2d into 3d structure
            [ data_EEG_3d ] = Giac_2d_3d_ft_Converter( data, '2d_to_3d' ); % ensures that dimord is 'rpt_chan_time'

            % Identify outlier on a trial by trial basis
            data3D   = data_EEG_3d.trial;
            std_mat  = nanstd(data3D,0,3); % std of each electrode for each trial
            mean_mat = nanmean(data3D,3);  % mean of each electrode for each trial

            max_mat  = nanmax(data3D,[],3);   % max of each electrode for each trial
            min_mat  = nanmin(data3D,[],3);   % min of each electrode for each trial
            ptp_mat  = max_mat + abs(min_mat);% peak to peak of each electrode for each trial
            
            [ indices_std  ] = Giac_StdOverMeanVectorFilter( nanmean(std_mat,1),  std_nr ); % deviating over-trials-mean of within-trial-std of one electrode with respect to all others
            [ indices_mean ] = Giac_StdOverMeanVectorFilter( nanmean(mean_mat,1), std_nr ); % deviating over-trials-mean of within-trial-mean of one electrode with respect to all others
            [ indices_ptp ] = Giac_StdOverMeanVectorFilter( nanmean(log(ptp_mat),1), std_nr );
            [ trial_flat,indices_flat] = find(round(mean_mat, 5) == 0);      % RB  find the channels that have zero activity
            [ trial_flat_std, indices_flat_std] = find(round(std_mat, 5) < 0.2);  % RB find the channels that have zero activity

            all_indices      = unique([indices_std indices_mean indices_ptp indices_flat indices_flat_std]); % RB added new indeces

            ele_names        = data.label(all_indices);

            if isempty(ele_names) == 0
                [ data ] = Giac_removeChannels( data, ele_names' );% Remove noisy channels from data_EEG
            elseif isempty(ele_names) == 1
                Go_recursive = 'no';
            end

        ele_names_all = [ele_names_all ele_names'];

        counter_recur = counter_recur + 1;
        display(['GIAC: recursive nr ' num2str(counter_recur)]);
        end % of while
end

for cc = 1: length (ele_names_all)
display(['Noisy electrodes: ' ele_names_all{cc}]); % mat2str(data_EEG.label{cc})
end

end

