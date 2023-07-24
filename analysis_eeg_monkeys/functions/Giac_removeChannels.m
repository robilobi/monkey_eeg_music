function [ data_out ] = Giac_removeChannels( data, channels_to_remove )
%
% This function eliminates the channels specified in 'channels_to_remove'
% from 'data'
%
%% Giacomo Novembre

% Add a minus in front of the labels in order to work with FT function
for n = 1:length(channels_to_remove)
    channels_to_remove{n} = ['-' channels_to_remove{n}];
end

% Select only channels of interest
cfg         = [];
cfg.channel = ['all', channels_to_remove];
data_out    = ft_selectdata(cfg,data);


end

