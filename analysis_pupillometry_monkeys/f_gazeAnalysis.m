% 
% This function checks gaze position and removes outlier trials
%
% input parameters are:
% (1) gazeData = x-y gaze data of one eye
% (2) scr = screen information defined in callExpCondList.m
% (3) pupilData  
% (3) checkFlag (=1 plot outcomes; 0=no plotting)
% output parameters are:
% (1) inRange = data index (1:data is in range; 0: data is out-of-range)
% (2) outPupil = pupil data after removing out-of-range data
%  05/01/2022 - Claudia Cw
%  27/04/2022 - Kaho Magami(edit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function [inRange, outPupil] = f_gazeAnalysis(gazeData,scr,pupilData,checkflag)
      
%% check the data dimension
[a,b] = size(gazeData);
if b>a  
    gazeData = gazeData'; [~,b] = size(gazeData);
end

if b ~= 2 % data shold only include xy info of one eye
    error('Invalid input format. gaze data must include xy info of one eye.')
end
[c,d] = size(pupilData);
if d>c  
    pupilData = pupilData'; 
end

%% calculate the gazepoints within the acceptable range + plot heatmap
inRange = f_gazeScatter(gazeData(:,1), gazeData(:,2),scr,checkflag);

%% Removes out-of-range Gaze Points from the Pupil Data (by setting them to 0)
outPupil = pupilData.*inRange;   

%     
%% plotting comparison of raw and gazecorrected data
if checkflag
    figure; hold on;
    plot(pupilData, 'k');
    plot(outPupil,'r');
    title({'Data before and after Gaze Removal'}, {'- Black=Before,Red=After'});
end