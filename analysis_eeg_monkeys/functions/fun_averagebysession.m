function [dd] = fun_averagebysession(data)

d = [];
dd = struct;
dd.label = data.label;
dd.elec = data.elec;
dd.fsample = data.fsample;

sessions  = unique(data.trialinfo(:,3));
for i = 1:length(sessions)
    cfg = [];
    cfg.trials = data.trialinfo(:,3) == sessions(i);
    tmp = ft_selectdata(cfg,data);
    cfg =[];
    cfg.preproc.demean = 'no';
    tmp2 = ft_timelockanalysis(cfg, tmp);
    dd.trial{i} = tmp2.avg;
    dd.trialinfo(i) = i;
    dd.time{i} = data.time{i};
    clear tmp tmp2
end

end