function [ nan_trials ] = Giac_findNanTrials( data, method )
%
% This function looks for trials where at least one channel has an entire
% series of Nans - implying it has been previously excluded due to outlying
% data. The trial numbers meeting these requirements are outputted. 
% 'Method' 'OnlyOne' gives you the trial even if just one channel has NaNs,
% while 'OnlyAll' gives you the trial only if all channels have NaNs. 
% % 'OnlyTrial' gives you the trials that contains NaN. It
% works for both datasets having trials with fixed or variable lenght. 
%
%% Giacomo Novembre

nan_trials = [];

%% Check if data is composed of trials having the same lenght or not
trials_dur = [];
for kk=1:length(data.trial)
trials_dur = [trials_dur length(data.trial{kk})]; % compute duration of all trials
end

%% Now look for NaNs
if length(unique(trials_dur)) == 1 % if all trials have equal duration, keep trials
    [ data_3D ] = Giac_2d_3d_ft_Converter( data, '2d_to_3d' ); %% Turn into 3D structure
    switch method
        case 'OnlyTrial' %% RB
            str_tr_ch = nanmean(data_3D.trial,2); % avg over channel
            for tr = 1:size(str_tr_ch,1)
                if isempty (find(isnan(str_tr_ch(tr,:))==1)) == 0
                    nan_trials = [nan_trials tr];
                end
            end
        case 'OnlyOne'
            str_tr_ch = nanmean(data_3D.trial,3); % avg over time
            for tr = 1:size(str_tr_ch,1)
                if isempty (find(isnan(str_tr_ch(tr,:))==1)) == 0
                    nan_trials = [nan_trials tr];
                end
            end
        case 'OnlyAll'
            str_tr_ch  = mean(data_3D.trial,3); % avg over time
            str_tr     = nanmean(str_tr_ch,2);
            nan_trials = find(isnan(str_tr)==1)';
    end
elseif length(unique(trials_dur)) > 1 % if all trials have NOT equal duration, keep trials
    nan_trials  = [];
    for tr=1:length(data.trial)
    tmp_data    = data.trial{tr};
    switch method
        case 'OnlyTrial' %% RB
            if  mean(isnan(mean(tmp_data,1))) == 1 % all values (channels/timepoints) are nans
                nan_trials = [nan_trials tr];
            end
        case 'OnlyOne'
            if isempty(find(isnan(tmp_data)==1)) == 0 % there is at least 1 nan
                nan_trials = [nan_trials tr];
            end
        case 'OnlyAll'
            if mean(isnan(tmp_data(:))) == 1 % all values (channels/timepoints) are nans
                nan_trials = [nan_trials tr];
            end
    end
    end
end

end

