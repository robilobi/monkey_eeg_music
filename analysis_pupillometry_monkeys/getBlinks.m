function [listBlinks] = getBlinks(dataAll,Fs, lengthW, pad)
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here

for mk=1:2
    for ses=1:26
        tmp=[];
        tmp=dataAll(mk).badFrames{ses};

        events = getLengthNanEvents(tmp);

        lengthWindow=ceil(Fs*lengthW);
        Pads=ceil(Fs*pad);
        blinks=find (events(:,2)>=Pads(1)+lengthWindow(1) & events(:,2)<=Pads(2)+lengthWindow(2));

        listBlinks{mk,ses}(:,1)=events(blinks,1);
        listBlinks{mk,ses}(:,2)=events(blinks,1)+events(blinks,2)-1;
        

    end
end

end