%% Analysis of notes
% Load midi files from which get the onset, Load Idyom surprise values
% Extract pitch, ITI, IOI, So Sp, Eo Ep Ecombined Scombined values for each
% note, AND divide notes by high vs low S (could be S overall, S onset Spitch)
% we take the notes with 20% highest or lowest values. 
%%%%%%%%%%%%%%% Roberta Bianco Oct 2022 - Rome %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addpath(['\MATools\fieldtrip-20220321\']); ft_defaults;
% addpath(['\MATools\NoiseTools\']);       % http://audition.ens.fr/adc/NoiseTools/
% addpath(['\MATools\mTRF-Toolbox-master\mtrf']); % add the mTRF toolbox functions
% addpath(['\MATools\matlab-midi-master\src\'])

clearvars; close all
addpath(pwd)
addpath("functions\")
cd('..\..\data\');
U = [pwd filesep];
% To get stim info
stimulus_path = ([U 'stimuli\']);
midi_path = [stimulus_path 'midiall\'];
svpth = stimulus_path; 

indexwhichSurprises = [1 2 3]; % 1 for allS, 2 for S pitch, 3 for S onset
features = {'PitchOnset', 'Pitch' , 'Onset'};

%%% VIEWPOINTS: CPITCH IOI-RATIO (as in Gold 2019 JN best winning model, and Di Liberto 2020)
idyomfl = [stimulus_path '89-cpitch_onset-cpitch_ioi-ratio-nil-nil-melody-nil-10-both+-nil-t-nil-c-nil-t-t-x-3.dat'];
possible_typeofctrl = {'IOI', 'ITI', 'ITOI', 'noCtrl'};
typeofctrl = possible_typeofctrl{4}; % select 1 of these types of control

midi_names = {'audio01.mid','audio02.mid','audio03.mid','audio04.mid','audio05.mid', ...
    'audio06.mid','audio07.mid','audio08.mid', 'audio09.mid','audio10.mid',...
    'shf01.mid','shf05.mid','shf08.mid','shf10.mid'};
code_corresponding_to_midi = [101:110 111 115 118 120];

%% CRETAE TRIAL INFO MATRIX
%%% GET IDYOM VARIABLE
headers = {'melody.name','information.content', 'cpitch', 'cpitch.information.content', 'onset.information.content','cpitch.entropy', 'onset.entropy'};
Sall = Nate_get_idyom_vars([idyomfl],headers,[0 1 1 1 1 1 1]);
%%% GET ALLNOTES MATRIX WITH [all_id allpitches allonsets alliti allioi S Sp So Ep Eo];
[allinfo_all_midi] = fun_get_onset_matrix(Sall, Sall, Sall, midi_path, midi_names, code_corresponding_to_midi);
midi_to_analyse = [1:14];

for k = 1:length(features)
    indexwhichSurprise = indexwhichSurprises(k); % 1 for allS, 2 for S pitch, 3 for S onset
    feature = features{k};
    allinfo = [];
    for i = midi_to_analyse
        id_midi_to_analyse = code_corresponding_to_midi(i);
        idx_midi_notes = ismember(allinfo_all_midi(:,1), id_midi_to_analyse);
        allinfo_thismel = allinfo_all_midi(idx_midi_notes,:);
        [allinfo_thismel2] = fun_control_forlocaltransitions(typeofctrl,allinfo_thismel, indexwhichSurprise);
        allinfo = [allinfo; allinfo_thismel2];
    end

    filename=([svpth 'Noteinfo_CondBy' feature '_' typeofctrl]);
    save(filename, 'allinfo'); csvwrite(filename,allinfo);
end
% allinfo [all_id allpitches allonsets alliti allioi S Sp So Ep Eo Cond];
% allinfo    1       2         3         4     5     6  7  8 9  10   11
