function [allinfo] = fun_get_onset_matrix(Sall, Sallp, Sallo, midi_path, midi_names, code_corresponding_to_midi)
%%%
% creates a matrix with Surprise values extracted from idyom files, iti,
% ioi for each note of each midi
% OUTPUT: allinfo     = [all_id allpitches allonsets alliti allioi S Sp So];
%%% Roberta Bianco Dec 2022

allonsets = [];
for i = 1:length(midi_names)
    midi_file_name  = midi_names{i};
    midi = readmidi([midi_path '\' midi_file_name],1);
    nmat = midiInfo(midi);
    note_onsets = nmat(:,5);
    allonsets = [allonsets; note_onsets];
end

allidyomnames    = [Sall.melody_name];
allpitches       = [Sall.cpitch];
all_id           = [];                                                  % how many semitones preceed the note
So               = [];
Sp               = [];
S                = [];
alliti           = [];
allioi           = [];
allpitches2      = [];
Ep=[];
Eo=[];

for s = 1:length(midi_names)                                         % Take pitches of one melody
    idyom_stim_name = sprintf('"%s"',midi_names{s}(1:end-4));
    stim_idx = cellfun(@(x) strcmp(x,idyom_stim_name), allidyomnames);

    %%% VALUES FROM THE ONSET PURE IDYOM MODEL (ONSET SURPRISE
    %%% PREDICTED BY ONSET

    this_mel_ioi = allonsets(stim_idx);
    ioi        = diff(this_mel_ioi);
    ioi        = [99; ioi];
    allioi     = [allioi; ioi];
    this_mel_So= [Sallo.onset_information_content(stim_idx)];
    So         = [So; this_mel_So];

    %%% VALUES FROM THE PITCH PURE IDYOM MODEL (PITCH SURPRISE
    %%% PREDICTED BY PITCH

    this_mel_pitch   = allpitches(stim_idx);
    iti              = abs(diff(this_mel_pitch));
    iti              = [99; iti];
    this_mel_Sp      = [Sallp.cpitch_information_content(stim_idx)];
    Sp               = [Sp; this_mel_Sp];
    alliti           = [alliti; iti];
    allpitches2      = [allpitches2; this_mel_pitch];

    %%% VALUES FROM THE FULL IDYOM MODEL (PITCH + ONSET SURPRISE
    %%% PREDICTED BY PITCH AND ONSET

    this_mel_S      = [Sall.information_content(stim_idx)];
    S               = [S; this_mel_S];

    %%% VALUES ENTROPY

    this_mel_Eo      = [Sall.onset_entropy(stim_idx)];
    Eo               = [Eo; this_mel_Eo];
    this_mel_Ep      = [Sall.cpitch_entropy(stim_idx)];
    Ep               = [Ep; this_mel_Ep];

    all_id  = [all_id; (repmat(code_corresponding_to_midi(s), length(this_mel_ioi),1))];
end

allinfo     = [all_id allpitches2 allonsets alliti allioi S Sp So Ep Eo ];

end