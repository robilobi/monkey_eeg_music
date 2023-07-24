function M = fun_TRFmake_idyom_designmatrix(S,stim_name,note_onsets,Fs,idyom_headers, varargin)
% Make a matrix of values where each column is a value at the sampling rate
% specified. The columns are:
% 1) onsets: 1 for note onset, 0 otherwise
% 2) pitch IC: IC value at note onset, 0 otherwise
% 3) pitch entropy: entropy value at note onset, 0 otherwise
% 4) onset IC: IC value at note onset, 0 otherwise
% 5) onset entropy: entropy value at note onset, 0 otherwise
% Inputs:
% - S = structure containing IDyOM stimulus variables (see
% get_idyom_vars.m)
% - stim_name = string of the stimulus name
% - dur = stimulus duration (s)
% - Fs = sampling rate (Hz)
% Nate Zuk (2022)

sound_delay = 0; % amount that the stimulus should be delayed (if there is a delay
    % between the trigger and the actual stimulus start)
zero_pad_end = 2; % amount of zeros to add at the end of the matrix (in seconds)

if ~isempty(varargin)
    for n = 2:2:length(varargin)
        eval([varargin{n-1} '=varargin{n};']);
    end
end

% Get the rows of the variables in S corresponding the desired stimulus
stim_idx = cellfun(@(x) strcmp(x,stim_name), S.melody_name);

% Setup the design matrix
dur = sound_delay+max(note_onsets)+zero_pad_end; % add 1 second after the last no
M = NaN(ceil(dur*Fs),length(idyom_headers)+1);

% Include note onsets
%%% (18-4-2022) The onsets from the IDyOM text file do not correspond to
%%% onset times in seconds. They will need to be converted somehow.
% 'Onsets' are defined in "basic time units", 24=quarter note
% 'Tempo' is some scaled version of the BPM, divide by 10000? Divide each
% onset time by beats-per-second to get the onset time in seconds
% onsets = S.onset(stim_idx)/24./(S.tempo(stim_idx)/600000);
% M(:,1) = delta_vec(onsets,ones(length(onsets),1),sound_delay,dur,Fs);
M(:,1) = delta_vec(note_onsets,ones(length(note_onsets),1),sound_delay,dur,Fs);

% Add the other variables
% idyom_headers = {'cpitch_information_content','cpitch_entropy','onset_information_content','onset_entropy'};

for ii = 1:length(idyom_headers)
    eval(sprintf('v = S.%s(stim_idx);',idyom_headers{ii}));
    M(:,ii+1) = delta_vec(note_onsets,v,sound_delay,dur,Fs);
end

%% Functions %%
function dlt = delta_vec(t,vals,sound_delay,dur,Fs)
% Create a delta function with non-zero values at times t
dlt = zeros(ceil(dur*Fs),1);
idx = round((t+sound_delay)*Fs)+1;
dlt(idx) = vals;