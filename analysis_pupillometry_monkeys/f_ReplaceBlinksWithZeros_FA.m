function [pupil_out,BlinksInfo] = f_ReplaceBlinksWithZeros_FA(pupil_in,RemoveDur,Fs,CheckFlag)

% ReplaceBlinksWithZeros - Replace blinks, including transient portions,
% with zeros.
%Usage: pupil_out = ReplaceBlinksWithZeros(pupil_in,RemoveDur, CheckFlag)
%pupil_in: pupil data
%RemoveDur: Durations to be removed before and after the blinks in sec. (2-element vec; default [0.15, 0.15])
%CheckFlag: If non-zero, plot waveforms before and after the blink removal (default: 0)
%By Shigeto Furukawa, 2012/12/17
% Edited by Maria Chait 2022/03/24 to not include tails in intervals that are too short.

%% relevant editable parameters

RemoveDurStart=RemoveDur(1); %Duration for removal before blink onset in sec.
RemoveDurEnd=RemoveDur(2); %Duration for removal after blink offset in sec.
removeThresh = 20; %will not include edges in 'blinks' shorter than this (in samples). 20 frames = 88ms

%%
%Output var
pupil_out=pupil_in;

%Indices for the analyses and removal
NRemoveStart=ceil(Fs*RemoveDurStart);
NRemoveEnd=ceil(Fs*RemoveDurEnd);
p=pupil_in;

%Detect blinks
myp1=diff([p; p(end)]);
myp2=diff([p(1); p]);
IdxBlinkStart=find(myp2<0 & p==0); %Negative slope -> zero
IdxBlinkEnd=find(myp1>0 & p==0); %zero -> Positive slope

if p(1) == 0, IdxBlinkStart = [1; IdxBlinkStart]; end  %to address the eventuality that the epoch starts with a blink

%     (Maria Chait edit) do not extend edges of blinks that are shorter than
%     'removeThresh'. This is ackomplished by removing these short "no data"
%     intervals from the list.


for (i=1:length(IdxBlinkEnd))
    if IdxBlinkEnd(i)-IdxBlinkStart(i)<removeThresh  %too short to be a blink, like issue with recording.
        IdxBlinkEnd(i)=nan;
        IdxBlinkStart(i)=nan;
    end
end

IdxBlinkStart=IdxBlinkStart(~isnan(IdxBlinkStart));
IdxBlinkEnd=IdxBlinkEnd(~isnan(IdxBlinkEnd));

BlinksInfo.start=IdxBlinkStart;
BlinksInfo.end=IdxBlinkEnd;

if CheckFlag
    %Plot entire original waveform
%     figure;
%     plot(p,'b');

end

%Mark the periods to be removed
if (~isempty(IdxBlinkStart) && ~isempty(IdxBlinkEnd))
    IdxRemoveStart=repmat(IdxBlinkStart,[1, NRemoveStart]) + repmat(-(1:NRemoveStart),[length(IdxBlinkStart),1]);
    IdxRemoveStart(IdxRemoveStart<1)=1;
    IdxRemoveEnd=repmat(IdxBlinkEnd,[1, NRemoveEnd]) + repmat(1:NRemoveEnd,[length(IdxBlinkEnd),1]);
    IdxRemoveEnd(IdxRemoveEnd>length(p))=length(p);

    %Replace with zeros
    p(IdxRemoveStart(:))=0;
    p(IdxRemoveEnd(:))=0;
end

pupil_out=p;

if CheckFlag
%     %Show the data after blinks removed.
%     hold on
%     plot(p,'r');
%     hold off
% 
%     xlabel('Time (sec)');
%     ylabel('pupil diameter');
%     title('Blue: Original; Red: After removal of blinks');
end


