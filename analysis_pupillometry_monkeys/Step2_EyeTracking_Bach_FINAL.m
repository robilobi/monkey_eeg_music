%%  SCRIPT TO ANALISE PUPIL WIDTH CORRECTED BY GAZE 
% fINAL PARAMETERS:
% - Analyse Gaze and take only points where the Mk holds the gaze around an arbitrary fixation cross centred around the median gaze for that recording session
% - Defines acceptable range of gaze around cross 0.5 units around fixation
% - Blink is defined with a window of 0.05 and 1.5 s, if within this range pad 100 ms before and after blink, if smaller just interpolate without padding, if larger put to nan as it might be a sleep moment
% - Use linear interpolation with no filtering
% - Bin 120 s song data into 0.5 s bins.
%  17/01/2023 - Roberta Bianco and Flavia Arnese
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;
clear all
C = 'C:\Users\farnese\Fondazione Istituto Italiano Tecnologia\Roberta Bianco - PUPIL\';
%C = 'C:\Users\robianco\OneDrive - Fondazione Istituto Italiano Tecnologia\BACHMK\PUPIL\';
addpath([C 'SCRIPTSpupil\FINAL']);
Fps=225.79 ;
audioNr = [1 2 3 4 5 6 7 8 9 10 11 12 13 14];

dataPath= [C 'DATA\MatData\'];
outPath=[C 'RESULTS\DATA_newPipeline'];

%% set some parameters
%interpolation
padPDR = [0.100,0.100]; % duration of zero-padding before and after blink [s]
lW=[0.05 1.5]; %within which interval to interpolate (nr as s) below 50 ms just interpolate, above 1.5 sec keep as NaN, in between pad and interpolate
%epoching
lenghtBins = 0.5; % insert nr in s, durations bins for epoching
%initialize
dataAll=struct;
%plot figures
plotFigs = 0;

%% START

% Loading data
fileNames = dir([dataPath filesep '*.mat']);


for s=1:length(fileNames)

    protocolFileName=sprintf('%s/%s', fileNames(s).folder, fileNames(s).name);
    sprintf('/// processing %s ///',fileNames(s).name(1:18))

    if strcmp(fileNames(s).name(1:7),'Monkey1')
        mNR=1;
        ss=s;
    elseif strcmp(fileNames(s).name(1:7),'Monkey2')
        mNR=2;
        ss=s-length(fileNames)/2;
    else
        sprintf('error! What monkeys is this?')
    end

    % load and rename
    Monkey=load(protocolFileName);
    fields = fieldnames(Monkey);
    Monkey = Monkey.(fields{1});

    %find triggers (both for wav or start/end block)
    [rows.Trig,~]=find(Monkey.Triggers~=10); %find all rows that are not data
    rows.TrigClean=find(~isnan(Monkey.TriggersNr)); %start melody
    rows.TrigClean(:,2)=Monkey.TriggersNr(rows.TrigClean); %which melody

    %% epoch and find blinks
    for i = 1:length(rows.TrigClean)

        songNr = rows.TrigClean(i,2);
        startData = rows.TrigClean(i);
        timezero = Monkey.TotalTime(startData+1);
        timend =timezero+125; % in sec = 2 min + 5 sec baseline
        [rows.Data,~]=find(Monkey.TotalTime>= timezero & Monkey.TotalTime<= timend+0.004); %adding almost 1 frame to make sure binning up to 2 mins (included)
        cleanedRaw = Monkey(rows.Data,:);

        disp(['**** Analysing blink data for Block ' fileNames(s).name ' ****']);
        tmp=cleanedRaw.PupilWidth;
        tmp(tmp<0.05)=0;   % put very low values to zero
        tmp(isnan(tmp))=0; % put nan values to zero

        % 1. analyse gaze data and mark "out of range" times
        % Monkey setting: pixel display 1366x768, Distance from Subject to
        % Screen = 140 cm; Width Of the screen in cm = 90 ( 40 pollici),
        % height 50cm
        scr = [];               %Stores parameters of the Display Screen
        scr.HRes=[min(Monkey.X_Gaze) max(Monkey.X_Gaze)];       %Horizontal Resolution
        scr.VRes=[min(Monkey.Y_Gaze) max(Monkey.Y_Gaze)];       %Vertical Resolution 
        scr.Center = [median(Monkey.X_Gaze, 'omitnan') median(Monkey.Y_Gaze, 'omitnan')];
        %scr.FSize = 0.5;         %Size of the fixation cross measurements
        scr.AccR = 0.5;          %Defines acceptable range of gaze around cross %100 pixels around fixation
        gazeData = [cleanedRaw.X_Gaze cleanedRaw.Y_Gaze]; %X Y
        disp(['**** Analysing gaze data for Block ' fileNames(s).name ' ****']);
        [~, rawPupilDataGazeCorrected] = f_gazeAnalysis(gazeData,scr,tmp,plotFigs); %checking gaze, values out of gaze are put to zero
       
        % 2. handle blinks and out-of-range gaze (different from blinkMS)  
        [deBlinkedPupilData, blinkPDR, allBlinks] = f_Blinkhandling_FA(rawPupilDataGazeCorrected,Fps,padPDR,1,plotFigs,lW); % from sijia
        interpolatedData = f_Interpolate(deBlinkedPupilData,plotFigs); 
        cleanedRaw.interpolatedData=interpolatedData';

        %put again to NaN longer sleep events
        blinks = getLengthNanEvents(blinkPDR);
        longB = find(blinks(:,2)>=ceil(Fps*lW(2)));
        toNaN= [blinks(longB,1) blinks(longB,1)+blinks(longB,2)-1];

        for lB=1:length(longB)
            cleanedRaw.interpolatedData(toNaN(lB,1):toNaN(lB,2))=nan;
        end
        data = cleanedRaw;


        %%  Bin data
        %first 5 sec after trigger is silence
        starttime=data.TotalTime(1); % time of song trigger
        pretime=starttime+5; %5 sec wait befor song start
        prerow=find(data.TotalTime<=pretime, 1, 'last' ); %find last frame of pre-time
        thisrow=prerow+1; %find first frame of song
                
        %find first time stamp, find last row within lengthBin, average
        %over these values; move to next section till exceeded last time
        %stamp   
        thistime= data.TotalTime(thisrow); %timing first frame of song
        c=1; %counting var

        while thistime + lenghtBins*c <= data.TotalTime(end)
            endtime = thistime + lenghtBins*c;
            endrow=find(data.TotalTime<=endtime, 1, 'last' ); %find last row of the bin

            if endtime<data.TotalTime(end)
                tmp1 = data.interpolatedData (thisrow:endrow); %extract relevant datapoints
                gzx = data.X_Gaze (thisrow:endrow); %extract relevant datapoints
                gzy = data.Y_Gaze (thisrow:endrow); %extract relevant datapoints

                if nnz(isnan(tmp1))<= length(tmp1)/2 %if not more than 50% NaN
                    binnedData(c) = median(tmp1,'omitnan'); %average over selected datapoints
                    binnedgzx(c) = median(gzx,'omitnan'); %average over selected datapoints
                    binnedgzy(c) = median(gzy,'omitnan'); %average over selected datapoints

                else
                    binnedData(c) = nan;
                    binnedgzx(c) =  nan;
                    binnedgzy(c) =  nan;
                end
            else 
                break
            end        
            thisrow=find(data.TotalTime>=endtime, 1, 'first' ); %find first row of next bin
            c=c+1;
        end

        %% organise data into structure
        dataAll(mNR).session(ss).badFrames{i}=blinkPDR; %index of bad points
        dataAll(mNR).session(ss).interpData{1,i}=data.interpolatedData;
        dataAll(mNR).session(ss).dataRows{i}=rows;
        dataAll(mNR).session(ss).song{i}=songNr;
        dataAll(mNR).session(ss).dataBin{i} = binnedData;
        dataAll(mNR).session(ss).datagzx{i} = binnedgzx;     
        dataAll(mNR).session(ss).datagzy{i} = binnedgzy;

    end
end
%save(sprintf('%s/data_wBadFrames_newBinning_%s.mat',outPath,datetime('now','Format','dd-MMM-uuuu')),'dataAll','-v7.3')
% organize data into table for lmer (binned data
count=0;
for mk=1:2
   for ses=1:length(fileNames)/2
        for mel=1:14
            dd = dataAll(mk).session(ses);
            for bins=1: length(dataAll(mk).session(ses).dataBin{1,1})
                count=count+1;
                tData(count).Melody=dd.song{mel};
                tData(count).bin=bins;
                tData(count).session=ses;
                tData(count).monkey=mk;

                if tData(count).Melody<11
                    tData(count).condition = 1;
                else
                    tData(count).condition = 2;
                end
                tData(count).PupilSize=dd.dataBin{mel}(bins);
                tData(count).datagzx=dd.datagzx{mel}(bins);
                tData(count).datagzy=dd.datagzy{mel}(bins);
            end
        end
    end
end
tableData=struct2table(tData);

save(sprintf('%s/data_table_%1.1fs_%s.mat',outPath,lenghtBins,datetime('now','Format','dd-MMM-uuuu')),'tableData','-v7.3')
writetable(tableData, sprintf('%s/pupil_bach_%1.1fs_%s.csv',outPath,lenghtBins,datetime('now','Format','dd-MMM-uuuu')))
