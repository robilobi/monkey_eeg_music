function [b] = getLengthNanEvents(Idx)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
 n=0;
        for j=1:length(Idx)
            if Idx(j)==1  && (j==1 ||Idx(j-1)==0) %if t=1 ok and now asleep
                n=n+1;
                k=0;
                while j+1+k<=length(Idx) && Idx(j+1+k)==1
                    k=k+1;
                end
                b(n,1)=j; %where it starts
                b(n,2)=k+1; %how long it lasts
            end
        end
end