clear; clc;

%addpath(genpath('./JEMR_2018-master/'))
%C = 'C:\Users\farnese\Fondazione Istituto Italiano Tecnologia\Roberta Bianco - PUPIL\';
C = 'C:\Users\robianco\OneDrive - Fondazione Istituto Italiano Tecnologia\BACHMK\PUPIL\';

dataPath=[C 'DATA\'];
outPath=[C 'DATA\matData'];mkdir(outPath);

% Note: Eye "A" refer to Mk2(T), Eye "B" refer to Mk1(M)
% Frame Rate Arrington ViewPoint --> 225.79
Fps=225.79 ;

% %% Setup the Import Options

opts = delimitedTextImportOptions("NumVariables", 25);
% Specify range and delimiter
opts.DataLines = [43, Inf];    % to improve ... for now check opening file .txt and see where is the start-Row
opts.Delimiter = "\t";
% Specify column names and types
opts.VariableNames = ["Triggers","TotalTime_A","DeltaTime_A","X_Gaze_A","Y_Gaze_A","X_CorrectedGaze_A","Y_CorrectedGaze_A","Region_A","PupilWidth_A","PupilHeight_A","Quality_A","Fixation_A","TotalTime_B","DeltaTime_B","X_Gaze_B","Y_Gaze_B","X_CorrectedGaze_B","Y_CorrectedGaze_B","Region_B","PupilWidth_B","PupilHeight_B","Quality_B","Fixation_B","Count","Marker"];
opts.VariableTypes = ["double","double","char","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double","double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

audioNames = {'audio01.wav','audio02.wav','audio03.wav','audio04.wav','audio05.wav','audio06.wav','audio07.wav','audio08.wav','audio09.wav','audio10.wav','shf01.wav','shf05.wav','shf08.wav','shf10.wav'};
audioNames_U0 = {'audio01.wav','audio02.wav','audio03.wav','audio04.wav','audio05.wav','audio06.wav','audio07.wav','audio08.wav','audio09.wav','audio10.wav','shf_audio01.wav','shf_audio05.wav','shf_audio08.wav','shf_audio10.wav'};

audioNr = [1 2 3 4 5 6 7 8 9 10 101 105 108 110];
beepNames={'Sine800.wav'};
beepNr=1;


%% START

% Loading data
fileNames = dir([dataPath filesep '*.txt']);

for s=1:length(fileNames)

    protocolFileName=sprintf('%s/%s', fileNames(s).folder, fileNames(s).name);
    sprintf('/// processing %s ///',fileNames(s).name(1:9))
    %protocolFileName='C:\Users\farnese\Fondazione Istituto Italiano Tecnologia\Roberta Bianco - PUPIL\DATA\U_MT_0_B_2022-5-30;13-57-35.txt';
    raw = readtable(protocolFileName, opts);
    rows.TrigClean=find(contains(raw.DeltaTime_A,'.wav'));

    if strcmp(fileNames(s).name(1:9),'01_U_MT_0')
        audN=audioNames_U0;
    else
        audN=audioNames;
    end

    %add variable with triggers as nr
    raw.TriggersNr=NaN(height(raw),1);
    for i=1:length(audN)
        tmp=find(strcmp(audN{i},raw.DeltaTime_A));
        raw.TriggersNr(tmp)=i;%audioNr(i);
    end
        tmp=find(strcmp(beepNames,raw.DeltaTime_A));
        raw.TriggersNr(tmp)=beepNr;


    Monkey=cell(2,1);

    Monkey{2}=raw(:,[1 2 3 4:12 26]);
    Monkey{1}=raw(:,[1 13 14 15:23 26]);

    %check if some consecutive rows have the same data (same time stamp and
    %same pupil value). NaN them out
    for m=1:2
         d=diff(Monkey{m}.(2)); %total time vector
         d=[d(1); d];
         dIdx=find(d==0);

         p=diff(Monkey{m}.(9)); %pupil width vector
         p=[p(1); p];
         count=0;
         pIdx=find(p==0);

         badI=intersect(pIdx,dIdx);
         if ~isempty(badI)
            Monkey{m}{badI,2:end}=NaN(length(badI),(size(Monkey{m},2)-1));
         end
         bI.nr(s,m)=length(badI);
         bI.detail{s,m}=badI;

         %take out _A / _B from variable names
         for n=2:length(Monkey{m}.Properties.VariableNames)-1
             Monkey{m}.Properties.VariableNames{n}=Monkey{m}.Properties.VariableNames{n}(1:end-2);
         end
    end
% 
% 
    Monkey2=Monkey{2};
    Monkey1=Monkey{1};
    save(sprintf('%s/Monkey1_%s.mat',outPath,fileNames(s).name(1:9)),"Monkey1")
    save(sprintf('%s/Monkey2_%s.mat',outPath,fileNames(s).name(1:9)),"Monkey2")

    Monkey1=[];
    Monkey2=[];

end
% save(sprintf('%s/AcquisitionIssueFrames.mat',dataPath),"bI")