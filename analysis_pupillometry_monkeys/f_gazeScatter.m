% 
% This function plots a scattergraph and a heatplot of Gaze Points and
% determines the out-of-range datapoints
%
% input parameters are:
% (1) X = x-axis gaze data
% (2) Y = y-axis gaze data
% (3) scr = screen information defined in callExpCondList.m
% (4) checkflag (=1 plot outcomes; 0=no plotting)
% output parameter is:
% (1) inRange = data index (1:data is in range; 0: data is out-of-range)
%
%  05/01/2022 - Claudia Cw
%  27/04/2022 - Kaho Magami(edit)
%  01/06/2022 - Kaho Magami(edit: change variable names)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function inRange = f_gazeScatter(X, Y,scr,checkflag)

%% fixing any extreme outliers (out of screen range) to screen edge
X(find(X<scr.HRes(1)))=scr.HRes(1); 
X(find(X>scr.HRes(2)))=scr.HRes(2);
Y(find(Y<scr.VRes(1)))=scr.VRes(1);
Y(find(Y>scr.VRes(2)))=scr.VRes(2);

%% calculate the gazepoints within the acceptable range
r = hypot(X-scr.Center(1),Y-scr.Center(2));
inRange = (r<=scr.AccR);

% calculate percentage of data in acceptable range
pointsInRange = [X(r<=scr.AccR,1) Y(r<=scr.AccR,1)];
percentage = (size(pointsInRange,1)/size(X,1))*100; 
disp(['**** % gaze points in range: ' num2str(percentage) ' ****']);


if checkflag
    %% Plot scattered data (for comparison):
    subplot(1, 2, 1); hold on;
    scatter(X, Y, 'b.'); % whole gaze data
    axis equal;
    set(gca, 'XLim', scr.HRes, 'YLim', scr.VRes);

    % Draw a circle representing an acceptable range for gaze
    viscircles(scr.Center, scr.AccR); 
    
    % plot data within the acceptable range
    plot(X(r<=scr.AccR,1),Y(r<=scr.AccR,1),'g.')
    
    % Draw where the fixation cross would be on the screen
    plot([scr.Center(1)-scr.FSize scr.Center(1)+scr.FSize], [scr.Center(2) scr.Center(2)],'r','MarkerIndices',2);
    plot([scr.Center(1) scr.Center(1)], [scr.Center(2)-scr.FSize scr.Center(2)+scr.FSize],'r','MarkerIndices',2);
    
    title([{'Gaze points within acceptable range:'}, {num2str(percentage) '%'}])
    
    %% Plot heatmap:
    subplot(1, 2, 2);
    % Bin the data:
    pts = linspace(scr.HRes(1),scr.HRes(2), 100);
    N = histcounts2(Y, X, pts, pts);
    imagesc(pts, pts, N);
    axis equal;
    set(gca, 'XLim', scr.HRes, 'YLim', scr.VRes, 'YDir', 'normal');
    title({'Heatmap of the gaze points:'}, {'Lighter = greater concentration'});
    
    % Draw a circle representing an acceptable range for gaze
    viscircles(scr.Center, scr.AccR); hold on;
        
    % Draw where the fixation cross would be on the screen
    plot([scr.Center(1)-scr.FSize scr.Center(1)+scr.FSize], [scr.Center(2) scr.Center(2)],'r','MarkerIndices',2);
    plot([scr.Center(1) scr.Center(1)], [scr.Center(2)-scr.FSize scr.Center(2)+scr.FSize],'r','MarkerIndices',2);
    subtitle('Gaze Analysis');    
    
end