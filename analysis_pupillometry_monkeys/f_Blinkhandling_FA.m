
function [outPupilData, outBlinkData, infoBlinks]=f_Blinkhandling_FA(rawPupilData,Fs,RemoveDur,doDerivativeAnalysis,checkflag,lengthWindow)

% This function carries out 2 separate stages of Blink Removal
% (1) Marks out sharp drops in the data as blinks, rendering them 0s
% (2) removes half blinks (by computing derivative and identifying samples
% that are +-7 std).
%input parameters are:
%(1) rawPupilData
%(2) Fs = sampling rate
%(3) RemoveDur = defining range of data to remove before/after each blink interval
%    recommendation for PDR analysis: [0.3 0.3]
%(4) doDerivativeAnalysis (1=half blink removal 0=skip this stage)
%(5) checkFlag (=1 plot outcomes; 0=no plotting)
%
% The function returns two variables:
% outPutpilData contains the "cleaned" pupil data. Blink intervals are
% replaced with NaNs.
% outBlinkData contains the intervals where blinks were identified (0=
% data; 1=blink
%
%Edited by Maria Chait 27/05/22
%Edited by Kaho Magami 31/05/22 (add RemoveDur)
%Edited by Maria Chait 14/06/22 (fix bug related to out of bounds padding)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% relevant parameters:

minIslandDuration = 100; %the minimum acceptable duration of an 'island' (data between NaNs).

%% checks that the pupil data are in the right orientation
[a b]=size(rawPupilData);
if b>a  % 'horizontal' vecotr
    rawPupilData=rawPupilData';
end

outPupilData=zeros(size(rawPupilData));
outBlinkData=zeros(size(rawPupilData));

for i=1: size(rawPupilData,2)
    pData=rawPupilData(:,i);
    %% De-Blinking Analysis Stage 1: Marks out sharp drops in the data as blinks, rendering them 0s
    [deBlinkedPupilData, infoBlinks] = f_ReplaceBlinksWithZeros_FA(pData,RemoveDur,Fs,checkflag);%modfied FA 19/12 _FA

    % replacing 0s with NaNs
    deBlinkedPupilData(deBlinkedPupilData ==0)=NaN;

    %Comparing de-Blinked data with raw data
%     if (checkflag)
%         figure;
%         plot(pData, 'k');
%         hold on
%         plot(deBlinkedPupilData,'g');
%         title(' Eye data before and after blink removal - black=before,green=after');
%     end

    %% De-Blinking Analysis Stage 2:  Remove partial eye closures based on pupil diameter derivative and standard deviation

    if (doDerivativeAnalysis ==1)
        %Indices for the analyses and removal
        NRemove=ceil(Fs*RemoveDur(1));

        Pn=deBlinkedPupilData;
        d = [diff(Pn)]; %derivative.

        % Identifies particularly large (7 std) pupil size changes
        speedrange = [nanmean(d)-7*nanstd(d) nanmean(d)+7*nanstd(d)];
        idxChange = find(d<=speedrange(1) | d>=speedrange(2));  %looking for unusual pupil size increases/decreases
        idxMax = find(Pn>0.28);

        %% find sleep events
        lengthW=ceil(Fs*lengthWindow);

        idxSleep=find(abs(d)<0.0001); %noChange added FA 19-12-22
        idx=union(idxChange,idxSleep);
        if ~isempty(idxMax)
            idx=union(idx,idxMax);
        end

        badIdxs=zeros(length(Pn),1);
        badIdxs(idx)=1;

        if sum(badIdxs == 0)
            blinks = 0;
        else
            blinks = getLengthNanEvents(badIdxs);
            longerBlinks = find(blinks(:,2)>=lengthW(1) & blinks(:,2)<=lengthW(2));
            bStart=blinks(longerBlinks,1);
            bEnd=bStart+blinks(longerBlinks,2)-1;
            toNaN=[bStart-NRemove bEnd+NRemove];
     

        for bb=1:length(bStart)
            if toNaN(bb,1)<1
                toNaN(bb,1)=1;
            elseif toNaN(bb,2)>length(Pn)
                toNaN(bb,2)=length(Pn);
            end
            Pn(toNaN(bb,1):toNaN(bb,2))=nan;
        end

        shortBlinks=blinks;
        shortBlinks(longerBlinks,:)=[];
        bStartS=shortBlinks(:,1);
        bEndS=bStartS+shortBlinks(:,2)-1;

        %now nan out again instances of very short bad frames (but without
        %extending window)
        for bb=1:length(bStartS)
            Pn(bStartS(bb):bEndS(bb))=nan;
        end
        end

        %% back to original script

        %         bStart=blinks(:,1);
        %         bEnd=bStart+blinks(:,2);
        %         if (~isempty(bStart))
        %             IdxRemove=[bStart-NRemove bEnd+NRemove];
        %             IdxRemove(IdxRemove<1)=1;
        %             Pn(reshape(IdxRemove, 1,size(IdxRemove,2)*size(IdxRemove,1))) =NaN;
        %         end
%         if (~isempty(idx))
%             IdxRemovePre=repmat(bStart,[1, NRemove]) + repmat(-(1:NRemove),[length(bStart),1]);
%             IdxRemovePost=repmat(bEnd,[1, NRemove]) + repmat((1:NRemove),[length(bEnd),1]);
%             IdxRemove=[IdxRemovePre IdxRemovePost];
%             IdxRemove(IdxRemove<1)=1;
%             Pn(reshape(IdxRemove, 1,size(IdxRemove,2)*size(IdxRemove,1))) =NaN;
%         end
%         
        %Plots results
        if (checkflag)
            figure;
            subplot(2,1,1)
            hold on
            plot(deBlinkedPupilData,'r');
            plot(Pn,'g');
            hold off;
            ylabel('Dilation Response');
            xlabel('');
            title('Eye data before and after futher blink removal: red = before, green = after');
            subplot(2,1,2)
            hold on
            plot(Pn,'g');
            ylabel('Dilation Response');
            xlabel('');
            title('Eye data after blink removal');
        end
        deBlinkedPupilData= Pn;
    end

    %% Removes "islands"
  %  deBlinkedPupilData=f_RemoveIslands(deBlinkedPupilData,minIslandDuration);

    deBlinkedPupilData=deBlinkedPupilData(1:length(outPupilData));
    outPupilData(:,i)=deBlinkedPupilData;  %deblinked pupil
    blink=zeros(size(deBlinkedPupilData));
     blink(find(isnan(deBlinkedPupilData)))=1;
    outBlinkData(:,i)= blink; %blink information

end

end



