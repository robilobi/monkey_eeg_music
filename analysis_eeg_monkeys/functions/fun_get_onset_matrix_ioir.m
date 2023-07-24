function [allinfo] = fun_get_onset_matrix_ioir(Sall, midi_path, midi_names, code_corresponding_to_midi)
%%%
% creates a matrix with Surprise values extracted from idyom files, iti,
% ioi for each note of each midi
% OUTPUT: allinfo     = [all_id allpitches allonsets alliti allioi S Sp So  itir ioir];
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
alliti           = [];
allioi           = [];
allpitches2      = [];
ioir = [];
itir = [];
S = []; Sp = [];  So = [];Eo = [];Ep = [];

for s = 1:length(midi_names)       
    this_mel_ioir =[];
    this_mel_itir = [];
    % Take pitches of one melody
    idyom_stim_name = sprintf('"%s"',midi_names{s}(1:end-4));
    stim_idx = cellfun(@(x) strcmp(x,idyom_stim_name), allidyomnames);

    %%% VALUES FROM THE ONSET PURE IDYOM MODEL (ONSET SURPRISE
    %%% PREDICTED BY ONSET

    this_mel_ioi = allonsets(stim_idx);
    ioi        = diff(this_mel_ioi);
    ioi        = [99; ioi];
    allioi     = [allioi; ioi];

    for j = 1:length(ioi)
        if j < 2
            ratio = 0.5;
        else
        ratio = ioi(j)/(ioi(j)+ioi(j-1));
        end
        this_mel_ioir= [this_mel_ioir; ratio];
    end
    ioir         = [ioir; this_mel_ioir];

    %%% VALUES FROM THE PITCH PURE IDYOM MODEL (PITCH SURPRISE
    %%% PREDICTED BY PITCH

    this_mel_pitch   = allpitches(stim_idx);
    iti              = abs(diff(this_mel_pitch));
    iti              = [99; iti];

    for j = 1:length(iti)
        if j < 2
            ratio = 0.5;
        else
        ratio = iti(j)/(iti(j)+iti(j-1));
        end
        this_mel_itir= [this_mel_itir; ratio];
    end
    itir             = [itir;  this_mel_itir];
    alliti           = [alliti; iti];
    allpitches2      = [allpitches2; this_mel_pitch];

    %%% VALUES FROM THE FULL IDYOM MODEL (PITCH + ONSET SURPRISE
    %%% PREDICTED BY PITCH AND ONSET

    this_mel_Sp      = [Sall.cpitch_information_content(stim_idx)];
    Sp               = [Sp; this_mel_Sp];

    this_mel_So      = [Sall.onset_information_content(stim_idx)];
    So               = [So; this_mel_So];

    this_mel_S      = [Sall.information_content(stim_idx)];
    S               = [S; this_mel_S];

    %%% VALUES ENTROPY
    this_mel_Eo      = [Sall.onset_entropy(stim_idx)];
    Eo               = [Eo; this_mel_Eo];
    this_mel_Ep      = [Sall.cpitch_entropy(stim_idx)];
    Ep               = [Ep; this_mel_Ep];

    all_id  = [all_id; (repmat(code_corresponding_to_midi(s), length(this_mel_ioi),1))];
end

allinfo     = [all_id allpitches2 allonsets alliti allioi S Sp So Ep Eo itir ioir ];

end