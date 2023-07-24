function [neweeg] = fun_avgtrialsbyname(eeg,namemelodies,stim_names)
neweeg=cell(length(namemelodies),1);
for n = 1:length(namemelodies)
    IndexC = strfind(stim_names, namemelodies{n});
    Index = find(not(cellfun('isempty',IndexC)));
    tmpeeg = eeg(Index);
    cutby = min(cellfun('size',tmpeeg,1)); %cut out some extra samples
    mateeg=zeros(cutby,size(tmpeeg{1},2),length(Index));
    for i =1:length(Index)
        mateeg(:,:,i) = tmpeeg{i}(1:cutby, :);
    end
    avgeeg = nanmean(mateeg,3);
    neweeg{n} = avgeeg;
end
end