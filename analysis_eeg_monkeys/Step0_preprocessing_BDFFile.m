%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preprocessing script for extracting  Monkey EEG data from BDF files
% * Each BDF file contains two subjects with 29 channels each
% * Stimulus labels are 101-118 (101-110 are original stimuli, 111-115-118-120 are
% shuffled/randomized)
% * The same 2 subjects run through 26 sessions with identical stimuli
% presented in randomised order per session (4 sessions are to be excluded
% due to corrupted data)
% - Preprocess the BDF file:
% filter, epoch, downsample, split EEG data into two subjects
% - Save each subject, each session separately:
%%%%%%%%%%%%%%% Roberta Bianco Oct 2022 - Rome %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addpath([ '\MATools\fieldtrip-20220321\']); ft_defaults;
% addpath(['\MATools\NoiseTools\']);       % http://audition.ens.fr/adc/NoiseTools/

clearvars; close all
addpath(pwd)
addpath("functions\")
cd('..\..\data\');
U = [pwd filesep];
% To get raw data
eegpth = ([U 'eeg\rawEEG\']);
% To store the preprocessed data
svpth = ([U 'eeg\preprocessedEEG\']); mkdir(svpth)
% To get stim info
stimulus_path = ([U 'stimuli\']);
midi_path = [stimulus_path 'midiall\'];
load('Layout_Monkey_EEG.mat');

desFs = 500;        % sampling rate of the EEG after downsampling
getsubstrALL        % EXCLUDE Sess 23; cell array called substr containing the names of the BDF files
subjects = [1 2];
sessionstoinclude  = [1:22 24:26];

all_eeg_sessions         = cell(2,length(substr));    % empty struc for animal 1 and 2
all_eeg_noisyChn         = cell(2,length(substr));    % store noisy electrodes
all_mic_sessions         = cell(1,length(substr));    % store mic data

for rep = 1:length(sessionstoinclude)
    session = substr{sessionstoinclude(rep)}(1:5);    % NAME 
    sessions = substr{sessionstoinclude(rep)}(6:end); % NAME day session


    %%% LOAD EEG
    reptag = sessions; %
    eegfnm = sprintf('%s%s_B.bdf',session,reptag);
    fprintf('Loading EEG for session %d...\n',rep);
    cfg = [];
    cfg.dataset = [eegpth eegfnm];
    dataload = ft_preprocessing(cfg);


    %%% DEFINE EVENTS (NO CUT YET) (take onset and offset trigger, 199 is offset for all trials)
    event = ft_read_event(cfg.dataset);
    trg = [100:110 111 115 118, 120, 199];
    NtrgTobefound = 28;
    [statusevent] = find(strcmp({event.type}, 'STATUS')==1);  %find cells with trg channel
    trgfound = [event(statusevent).value];                    %find cells with trg events
    trgidx = statusevent(ismember(trgfound, trg));            %find idx of trg of interest
    cfgtr =[];
    count = 1;
    for e = 1:2:length(trgidx)                                 % loop through triggers of interest
        cfgtr.trl(count,1) = event(trgidx(e)).sample;          % onset
        cfgtr.trl(count,2) = event(trgidx(e)+1).sample;        % offset
        cfgtr.trl(count,3) = 0;                                % trigger time
        cfgtr.trl(count,4) = event(trgidx(e)).value;
        count = count + 1;
    end
    disp(['... EVENT struct is ' num2str(size(event, 2)) ' long (Check if longer than 32)']); % some sessions contain artefacts in the event structure e.g. when CRM was out of range
    disp(['... FOUND ' num2str( [event(trgidx).value]) '...TRIGGERS']);
    disp(['... FOUND ' num2str(length(trgidx)) '...EVENTS']);
    if length(trgidx) ~= NtrgTobefound
        disp('CHECK THE EVENT STRUCTURE, SOMETHING IS ODD!!!');
    end


    %%% STORE MIC DATA AT ORIGINAL SR
    cfg = [];
    cfg.channel= {'1-Erg1', '2-Erg2'};
    micdata = ft_selectdata(cfg, dataload);
    all_mic_sessions{rep} = micdata;


    %%% BAND PASS 1-30 HZ
    cfg = [];
    cfg.lpfilter             = 'yes';
    cfg.lpfreq               =  30;
    cfg.lpfilttype           = 'but';
    cfg.lpfiltord            = 3;
    cfg.hpfilter             = 'yes';
    cfg.hpfreq               = 1;
    cfg.hpfilttype           = 'but';
    cfg.hpfiltord            = 3;
    dataload = ft_preprocessing(cfg, dataload);


    %%% CUT INTO EPOCH
    NtrialsTobefound = 14;
    data = ft_redefinetrial(cfgtr, dataload);
    % correct first session triggers
    if strcmp(eegfnm, 'U_MT_0_B.bdf')
        trg = [118, 105, 104, 111, 107, 106, 109, 101, 108, 110, 102, 115, 103, 120];
        data.trialinfo(:) = trg';
    end
    disp(['... EPOCHED ' num2str( num2str(data.trialinfo(:)')) '...TRIGGERS']);
    if length(data.trialinfo(:)) ~= NtrialsTobefound      % check the event structure something is odd
        break
    end

    %%% DOWNSAMPLE AT A RESONABLE HIGH SR FOR ASR
    cfg                      = [];
    cfg.resamplefs           = desFs;
    cfg.detrend              = 'no';
    cfg.demean               = 'no';
    [data]                   = ft_resampledata(cfg, data);
    dualdata = data;


    svfnm = sprintf('%s_sess%d','dualeeg', rep);
    save([svpth svfnm],'dualdata');
end
svfnm = sprintf('%s','micdata');
save([svpth svfnm],'all_mic_sessions');

