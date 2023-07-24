function  [data_out] = fun_load_epoch_eeg_ioir(file, allinfo, midi_names,code_corresponding_to_midi, midi_to_analyse, midi_path, sbj)

load(file);

% allinfo [all_id allpitches allonsets alliti allioi S Sp So Cond ];
% allinfo    1       2         3         4     5     6  7  8   9

%%% Remove session 12 and 13
cfg = [];
cfg.trials =  find(dataallsessions.trialinfo(:,2)~=12 & dataallsessions.trialinfo(:,2) ~= 13);
dataallsessions = ft_selectdata(cfg, dataallsessions); % amend data to only keep good trials
%%% Recreate missing channels
if sbj == 1
    dataallsessions = Giac_EEG_CreateElectrodes(dataallsessions, {'Cz','CPz', 'FCz', 'Fz'}, 'Layout_Monkey_EEG', .20); % .20 is better for central electrodes
elseif sbj == 2
    dataallsessions = Giac_EEG_CreateElectrodes(dataallsessions, {'Cz','CPz', 'F2', 'Fz'}, 'Layout_Monkey_EEG', .20); % .20 is better for central electrodes
end

%%%% EPOCHING
baseline_dur = 5; % IN S
new_sampling = dataallsessions.fsample; % in Hz
n_offsets    = [.050 .150]; % in s
condinfo = allinfo(:,[1 11 6 4 5 7 8]);
[data_out] = Robs_MiniTrialMaker_flagNotes(dataallsessions,midi_names(midi_to_analyse),code_corresponding_to_midi(midi_to_analyse),midi_path,baseline_dur,new_sampling,n_offsets, condinfo);
clear dataallsessions

[ nan_trials ] = Giac_findNanTrials( data_out, 'OnlyTrial' ); % session 12 contains some NaN
[data_out] = Giac_removeTrials(data_out,nan_trials,'reject');
idxsubj = size(data_out.trialinfo,2)+1;
data_out.trialinfo(:,idxsubj) = sbj;
% data_out.trialinfo = melNumber, melID, Session, Note Number, Surprise Condition, IC, ITI, IOI, subject

end

