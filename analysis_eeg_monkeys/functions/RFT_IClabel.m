function [ft_struct,rejected_comps] = RFT_IClabel(ft_struct,eeglab_template_file,threshold, pcaDim)
%%% From a fieldtrip structure (with N trials), concatenates all trials,   
%%% create an eeglab structure with this 'single concatenated trial',       
%%% cleans the data with ASR, based on cutoff and windowlen                 
%%%                                                                         
%%% Inputs:
%%% ft_struct                 Fieldtrip struct with the original data
%%% eeglab_template_file      Name of the file of your eeglab template
%%% cutoff                    Cutoff parameter for ASR datacleaning
%%% windowlen                 Window length parameter for ASR datacleaning
%%% ref_tolerances            SD of outliers in power determined for the
%%%                           reference data
%%% 
%%% Output:
%%% ft_struct                 Fieldtrip struct with the asr-cleaned data
%%% Atesh & Fefe & Trinh & Robs - Oct 2022 %%%

%%%% CONCATENATE ALL YOUR TRIALS %%%%
all_trials = cat(2,ft_struct.trial{:});


%%%%    CONVERT FIELDTRIP STRUCT TO EEGLAB STRUCT     %%%%
%%%% (! might need to be validated and/or improved !) %%%%
%%%% (inspired by EEGlab func. 'fieldtrip2eeglab.m')  %%%%

%%% load template to create eeglab structure %%%
eeglab_template = load(eeglab_template_file);
eeglab_struct = eeglab_template.eeglab_template;

%%% update the data field (Nchan x Ntime) %%%
eeglab_struct.data = all_trials;

%%% update other fields of interest %%%
[eeglab_struct.nbchan , eeglab_struct.pnts] = size(all_trials);         % number of channels , number of time points
eeglab_struct.trials = 1;           % because 1 big trial (of concatenated data)
eeglab_struct.srate = ft_struct.fsample;         % important if you have a sampling rate ≠ 2048Hz

%%% update chanlocs if you have removed channels %%%
chans_removed_in_ft=[];
for ch=1:length(eeglab_struct.chanlocs)
    if ~ismember(eeglab_struct.chanlocs(ch).labels,ft_struct.label)   chans_removed_in_ft(end+1)=ch;        end
end
eeglab_struct.chanlocs(chans_removed_in_ft) = [];

%%% reorder chanlocs if the channels are order differently in ft struct
%%% (can happen for ex if you interpolated channels)
assert(length(ft_struct.label)==length(eeglab_struct.chanlocs),'eeglab chanlocs should have same number of channels that ft struct');
for ch=1:length(ft_struct.label)
    new_idx(ch) = find(strcmp(ft_struct.label(ch) , {eeglab_struct.chanlocs.labels}));
end
eeglab_struct.chanlocs = eeglab_struct.chanlocs(new_idx);

% The following part is maybe not necessary (it updates the time
% information, saying "tStart = tStart of the original data in trial 1" and
% then deducting tStop based on srate and the num of time points concatenated
% (eg, you concatenated 3 trials [-1s, 10s], it's gonna create [-1s,32s]))
eeglab_struct.xmin = ft_struct.time{1}(1);
eeglab_struct.xmax =  eeglab_struct.xmin + (eeglab_struct.pnts-1)/eeglab_struct.srate;
eeglab_struct.times = eeglab_struct.xmin : 1/eeglab_struct.srate : eeglab_struct.xmax;


%%%% CALL IClabel %%%%
eeglab; close; % add paths to EEGLAB

eeglab_struct = pop_runica(eeglab_struct, 'icatype', 'runica', 'pca', pcaDim);
eeglab_struct = iclabel(eeglab_struct);
pop_viewprops(eeglab_struct, 0, 1:pcaDim, [], [], [], 'IClabel') % for component properties

[maxprob , maxcat] = max(eeglab_struct.etc.ic_classification.ICLabel.classifications , [] , 2);
flagReject = zeros(1,size(eeglab_struct.icaweights,1))';
for iCat = 1:7
    % detect ICs which highest probability is that of the category iCat,
    % and that this probability is also higher than the threshold you set
    % (eg if the highest prob is eye, but 5%, you might not want it)
    tmpReject  = maxcat==iCat & eeglab_struct.etc.ic_classification.ICLabel.classifications(:,iCat) > threshold(iCat,1) & eeglab_struct.etc.ic_classification.ICLabel.classifications(:,iCat) < threshold(iCat,2);
    flagReject = flagReject | tmpReject;
end
rejected_comps = find(flagReject > 0);
disp('RFT_IClabel: rejected components: ')
disp(rejected_comps)

% Remove the ICs
eeglab_struct = pop_subcomp(eeglab_struct, rejected_comps);

%%%% SEGMENT THE DATA BACK IN TRIALS %%%%
ica_cleaned_combined_trials = double(eeglab_struct.data);       % take the cleaned concatenated data from eeglab struct
[nChan,nTimePoints] = size(ft_struct.trial{1,1});
ft_struct.trial = mat2cell(ica_cleaned_combined_trials,nChan,cell2mat(cellfun(@(x) size(x,2),ft_struct.trial,'UniformOutput',0)));      

end