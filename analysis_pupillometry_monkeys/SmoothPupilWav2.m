function pupil_out = SmoothPupilWav2(pupil_in,CutFreq)
% SmoothPupilWav - Remove blinks marked with zeros, linear interporate, and lowpass filter.
%Usage: pupil_out = SmoothPupilWav(pupil_in,CutFreq)
%pupil_in: pupil matrix; Colmun1: time in ms; Colmun2-3: pupil data
%CutFreq: Cut-off frequency in Hz (default: no filtering)
%By SF, 2012/12/17
% Updated by Sijia Zhao (2016/10/06) to handle one eye pupil data
% Updated by Sijia ZHAO (2016/11/10)
if nargin <2
    CutFreq=NaN;
end

%Output var
pupil_out=pupil_in;

%Extract data
t=pupil_in(:,1);
t=t-t(1);
NData=size(pupil_in,2)-1;

%sampling rate
myt=diff(t);
Fs=1/myt(1)*1000;

%Filter coefficients
if ~isnan(CutFreq)
    [B,A]=butter(4,CutFreq/(Fs/2));
end

for iData=1:NData
    p=pupil_in(:,iData+1);
    
    %     if sum(p==0)==numel(p)
    %         p=p*NaN;
    %     end
    IdxUse = find(p~=0 & ~isnan(p));
    if ~isempty(IdxUse)  %if there is number in this row % 20161006
        
        if p(1) == 0 || isnan(p(1))
            p(1)=p(IdxUse(1));
            IdxUse=[1; IdxUse];
        end
        if p(end)==0 || isnan(p(end))
            p(end)=p(IdxUse(end));
            IdxUse=[IdxUse; length(p)];
        end
        
        %remove zeros, and interpolate
        p_i = interp1 (t(IdxUse),p(IdxUse),t,'pchip');
        if ~isnan(CutFreq)
            p_i = filtfilt(B,A,p_i);
            %keyboard
        end
        
    else % all NaNs: i.e. not recorded % 20161006
        p_i=p; % 20161006
    end % 20161006
    
    %2016/11/10 sijia added to solve the large value introduced by
    %interpolation of missing data e.g. S2 taskD
    %     p_i(p_i>2*median(p_i))=NaN; %sijia
    %     p_i(p_i<2*median(p_i))=NaN; %sijia
    
    pupil_out(:,iData+1)=p_i;
end
