function [all_erp_all_midi] = RFT_MiniTrialMaker(data,midi_names,code_corresponding_to_midi,dir_midi_files,baseline_dur,new_sampling,n_offsets)
%
% midi_names = cell with strings containing the names of the files of
% interest
% code_corresponding_to_midi = trigger codes, present in the FieldTrip
% data structure, associated to the midi_names (Note: the order has to be
% consistent!)
% dir_midi_files = dorectory where to find the midi files
% baseline_dur = duration of baseline period in s (must be consistent
% across all trials)
% new_sampling = new sampling rate (in Hz)
% n_offsets = 2 values, how much time you want to have before and after the
% note of interest (in s)
%% Giac & Robs

addpath('C:\Users\robianco\OneDrive - Fondazione Istituto Italiano Tecnologia\MATools\matlab-midi-master\src\'); % tools for getting midi information

tr_info = data.trialinfo; 
n_offsets = n_offsets * new_sampling;
all_tr_all_midi = [];

for i = 1:length(midi_names)
    tmp = code_corresponding_to_midi(i);
    instances_of_same_midi = find(tr_info(:,1)==tmp);

    cfg              = [];
    cfg.trials       = instances_of_same_midi'; 
    EEG_of_same_midi = ft_selectdata(cfg,data);
    if  isfield(EEG_of_same_midi, 'sampleinfo')
        EEG_of_same_midi = rmsubfield(EEG_of_same_midi, 'sampleinfo');
    end

    % Find MIDI note onsets

        midi_file_name  = midi_names{i}; 
        midi = readmidi([dir_midi_files '\' midi_file_name],1);
        nmat = midiInfo(midi);
        note_onsets = nmat(:,5);
        note_onsets = note_onsets + baseline_dur;

        all_tr_same_midi = [];

        for ii = 1:length(instances_of_same_midi) % loop into same exposure of 1 song

            cfg              = [];
            cfg.trials       = ii; 
            EEG_of_one_midi  = ft_selectdata(cfg,EEG_of_same_midi);
        
            cfg                              = [];
            cfg.trl(:,1)                     = round(note_onsets * new_sampling)-n_offsets(1);% samples
            cfg.trl(:,2)                     = round(note_onsets * new_sampling)+n_offsets(2);% samples
            cfg.trl(:,3)                     = -n_offsets(1);% samples
            cfg.trl(:,4)                     = i;
            cfg.trl(:,5)                     = EEG_of_one_midi.trialinfo(1); % melody ID 
            cfg.trl(:,6)                     = EEG_of_one_midi.trialinfo(2); % session ID 
            EEG_epochs_of_one_midi           = ft_redefinetrial(cfg,EEG_of_one_midi);
            all_tr_same_midi{ii}             = EEG_epochs_of_one_midi;
        end

        all_erp_same_midi = ft_appenddata([],all_tr_same_midi{:});
        all_erp_same_midi.fsample = new_sampling;
        all_tr_all_midi{i} = all_erp_same_midi;

end % loop

all_erp_all_midi = ft_appenddata([],all_tr_all_midi{:});

end % function