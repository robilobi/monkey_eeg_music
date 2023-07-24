function [ data_out ] = Giac_EEG_CreateElectrodes(data, channels_to_interpolate, layout_file_name, neighb_dist)
% This function performs ad hoc interpolation for specific electrodes. If
% these electrodes do not exist, they are created ex novo and the data
% filled in following interpolation. 
%% Giacomo Novembre

% Step 1 - change data file in order to host more channels
for ch_to_add = 1: length(channels_to_interpolate)
    tmp_ch = channels_to_interpolate{ch_to_add};    
    if isempty(find(ismember(data.label,tmp_ch)==1))==0 % channels already exists
        display(['GIAC: channel ' tmp_ch{1,1} ' already exists and will not be created']);
    elseif isempty(find(ismember(data.label,tmp_ch)==1))==1 % channels does not exists  
        data.label{end+1,1} = tmp_ch;        
        for tr = 1: size(data.trial,2)
            tmp_data = nan(1,size(data.trial{tr},2));
            data.trial{1,tr}(length(data.label),:) = tmp_data;
        end
    end
end

% Prepare layout
load(layout_file_name); % this normally load a 'lay' structure
cfg.layout          = lay;
layout              = ft_prepare_layout(cfg, data);

% Interpolation
cfg                 = [];
cfg.layout          = layout;
cfg.method          = 'distance'; % for prepare_neigh
cfg.neighbourdist   = neighb_dist;         % results in avg 5 channels
cfg.neighbours      = ft_prepare_neighbours(cfg, data);
cfg.badchannel      = channels_to_interpolate';
cfg.method          = 'nearest';     
data_out            = ft_channelrepair(cfg, data);

end

