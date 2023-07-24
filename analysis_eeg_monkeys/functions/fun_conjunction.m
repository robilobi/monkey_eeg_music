function [values, order_chan] = fun_conjunction(stats, filename)
load('Layout_Monkey_EEG.mat');
order_chan = lay.label;
h=figure;clf
h.Position = [100 100 800 700];
time = stats{1, 1}.time;
m1_label = stats{1,1}.label;
m2_label = stats{1,2}.label;
[a, ord] = ismember(order_chan, m1_label);
order(:,1)=ord;
[a, ord] = ismember(order_chan, m2_label);
order(:,2)=ord;
m1 = stats{1,1}.mask(order(:,1),:);
m2 = stats{1,2}.mask(order(:,2),:);
mconj = (m1+m2);
mconj(mconj~=2) = 0; %set non common values to zero
mconj(mconj==2) = 1; %set non common values to zero

for s = 1:2
    limits = [-6 6];
    stat = stats{1,s};
    if ~isfield(stat, 'posclusterslabelmat')
        stat.posclusterslabelmat = zeros(size(order_chan,1),length(time));end
    if ~isfield(stat, 'negclusterslabelmat')
        stat.negclusterslabelmat = zeros(size(order_chan,1),length(time));end
    M = stat.mask(order(:,s),:).*(stat.posclusterslabelmat(order(:,s),:)-stat.negclusterslabelmat(order(:,s),:));
    subplot(1,3,s);
    imagesc(time,1:length(order_chan),M, limits);hold on;
    yticks(1:size(order_chan,1));
    yticklabels(order_chan);
    title(['Mk ' num2str(s)])
    colormap(flipud(brewermap(64,'RdBu')));
end

subplot(1,3,s+1);
imagesc(time,1:length(order_chan),M.*mconj, limits);
yticks(1:size(order_chan,1));
yticklabels(order_chan);title('Conjunction');
saveas(gcf, [filename '.png']);

values  = M.*mconj;

end