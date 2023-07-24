%% Function that applies interpolation to a dataset
%  27/05/2022 - Claudia Cw
%  01/06/2022 - Kaho Magami (edit: add flagFigs and size check)
%
% This function recieves:
% (1) data: A matrix of data in the structure [Trials x Time]
% (2) flagFigs: 1=output figure; 0=no figure output
%
% This function produces 1 output:
% (1) interpolatedData: A matrix of data with identical structure to input(1),
%     but containing data that has been interpolated to it to bridge any gaps of missing information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function interpolatedData=f_Interpolate(data,flagFigs)

%% checks that the pupil data are in the right orientation

[a,b] = size(data);
if a>b  
    data = data';
end

%% Interpolate the data

for ip = 1:size(data,1)
    Tr = data(ip,:); Tr = Tr';                      %Loops through each trial
    timeInterpolate = 1:numel(Tr);
    Tr = SmoothPupilWav2([timeInterpolate',Tr]);    %Applies Interpolation function %MODIFIED FA 19/12 cutoff 4hz
    interpolatedData(:,ip) = Tr(:,2); 
end

interpolatedData = interpolatedData';               %Stores the interpolated dataset

%% plot
if flagFigs
    figure; hold on;
    plot(interpolatedData', 'k');
    plot(data', 'g');
    title({'Data before and after Interpolation'}, {'- Green = Before, Black = After'});
end
end 