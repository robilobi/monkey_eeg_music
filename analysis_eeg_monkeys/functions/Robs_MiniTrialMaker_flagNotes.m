function [all_erp_all_midi] = Robs_MiniTrialMaker_flagNotes(data,midi_names,code_corresponding_to_midi,dir_midi_files,baseline_dur,new_sampling,n_offsets, allnotes)
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
% !!!!!!!!!!!!!allnotes = matrix with all notes per each midi: 
% col 1 = trigger midi, 
% col 2 = cond (1 , 2), 
% col 3 = other;
% col 4 = other
% clo 5 = other
%% Giac & Robs

tr_info = data.trialinfo; 
n_offsets = n_offsets * new_sampling;
all_tr_all_midi = [];

for i = 1:length(midi_names)

    tmp = code_corresponding_to_midi(i);
    instances_of_same_midi = find(tr_info(:,1)==tmp);

    idxnotes =  find(ismember(allnotes(:,1), tmp));  % find index of this melody
    notesinfo = allnotes(idxnotes, :);

    cfg              = [];
    cfg.trials       = instances_of_same_midi'; 
    EEG_of_same_midi = ft_selectdata(cfg,data);
    
    if  isfield(EEG_of_same_midi, 'sampleinfo')
        EEG_of_same_midi = rmsubfield(EEG_of_same_midi, 'sampleinfo');
    end
    % Find MIDI note onsets

        midi_file_name  = midi_names{i}; % ['shf_audio' str '.mid'];
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
            EEG_epochs_of_one_midi.trialinfo(:,4) = 1:length(EEG_epochs_of_one_midi.trialinfo);
            EEG_epochs_of_one_midi.trialinfo(:,5) = notesinfo(:,2);  % condition of notes
            EEG_epochs_of_one_midi.trialinfo(:,6) = notesinfo(:,3);  % Surprise
            if size(notesinfo,2) > 4
                EEG_epochs_of_one_midi.trialinfo(:,7) = notesinfo(:,4);  % ITI
                EEG_epochs_of_one_midi.trialinfo(:,8) = notesinfo(:,5);  % IOI
                EEG_epochs_of_one_midi.trialinfo(:,9) = notesinfo(:,6);  % Sp
                EEG_epochs_of_one_midi.trialinfo(:,10) = notesinfo(:,7);  % So
            end

            all_tr_same_midi{ii} = EEG_epochs_of_one_midi;
        end

        all_erp_same_midi = ft_appenddata([],all_tr_same_midi{:});
        all_erp_same_midi.fsample = new_sampling;
        all_tr_all_midi{i} = all_erp_same_midi;
end % loop

all_erp_all_midi = ft_appenddata([],all_tr_all_midi{:});

end % function