function [ft_struct , ft_ref_section, ft_eigen_ref_time, ft_eigen_ref_topo, sample_mask] = RFT_clean_asr_combined_trials_ftstruct(ft_struct,eeglab_template_file, cutoff,windowlen,ref_maxbadchannels,ref_tolerances)
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

if nargin <3
    cutoff = [];
end

if nargin <4
    windowlen = [];
end

if nargin <5
    ref_maxbadchannels = [];
end

if nargin <6
    ref_tolerances = [];
end

%%%% CONCATENATE ALL YOUR TRIALS %%%%
all_trials = cat(2,ft_struct.trial{:}); % if fieldtrip 


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

% The following part is maybe not necessary (it updates the time
% information, saying "tStart = tStart of the original data in trial 1" and
% then deducting tStop based on srate and the num of time points concatenated
% (eg, you concatenated 3 trials [-1s, 10s], it's gonna create [-1s,32s]))
eeglab_struct.xmin = ft_struct.time{1}(1);
eeglab_struct.xmax =  eeglab_struct.xmin + (eeglab_struct.pnts-1)/eeglab_struct.srate;
eeglab_struct.times = eeglab_struct.xmin : 1/eeglab_struct.srate : eeglab_struct.xmax;



%%%% CALL ASR %%%%
usegpu = true;        % decide whether you run ASR on GPU or not
%%% RB: modified clean_asr function to get the cleaned reference data as
%%% output
[asr_cleaned_eeglab_struct, ref_section, eigen_ref_section, sample_mask] = RFT_clean_asr(eeglab_struct,cutoff,windowlen,[],[],ref_maxbadchannels,ref_tolerances,[],usegpu);  % asr
asr_cleaned_combined_trials = asr_cleaned_eeglab_struct.data;       % take the cleaned concatenated data from eeglab struct


%%%% SEGMENT THE DATA BACK IN TRIALS %%%%
[nChan,nTimePoints] = size(ft_struct.trial{1,1});
ft_struct.trial = mat2cell(asr_cleaned_combined_trials,nChan,cell2mat(cellfun(@(x) size(x,2),ft_struct.trial,'UniformOutput',0)));      

%%%% RB FB: return clean reference data for ASR with whole data 
trial = ref_section.data;
ft_dummy = struct;
ft_dummy.trial{1} = trial;
ft_dummy.fsample = ft_struct.fsample;
ft_dummy.time{1} = linspace(0,size(trial,2)/ft_dummy.fsample, size(trial,2));
ft_dummy.label = ft_struct.label;
ft_ref_section = ft_dummy;

%%% return also the PCs detected in ref section
% Time curve
eigen_ref_section_flip = flip(eigen_ref_section,2);     % sort PCs from higher variance to lower
eigen_ref_section_weights = abs((ref_section.data)' * eigen_ref_section_flip)';     % get temporal curve of PCs
ft_dummy = struct;
ft_dummy.trial{1} = eigen_ref_section_weights;
ft_dummy.fsample = ft_struct.fsample;
ft_dummy.time{1} = linspace(0,size(trial,2)/ft_dummy.fsample, size(trial,2));
for pc=1:size(eigen_ref_section_weights,1)
    ft_dummy.label{pc,1} = ['PC' num2str(pc)];
end
ft_eigen_ref_time = ft_dummy;

% Topographies
ft_dummy = struct;
ft_dummy.topo = eigen_ref_section_flip;
for pc=1:size(eigen_ref_section_weights,1)
    ft_dummy.label{pc,1} = ['PC' num2str(pc)];
end
ft_dummy.topolabel = ft_struct.label;
ft_eigen_ref_topo = ft_dummy;

end