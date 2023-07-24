function  [Matrixintegrale, Matrixmean] = fun_write_erpmatrix_final_HM(data_forlme, sbj, values, order_chan, clvalue)
%% Make matrix for stats
% data contains selected trials by condition
% compute = 'mean', or 'area'
% it handles 3 clusters max
label = data_forlme.label;
[a, ord] = ismember(label, order_chan); %ord is the index of how the order_chan map onto the current labels

cl1 = values == clvalue(1); % find where the cluster is
m1 = cl1(ord,:); % reoder mask according to channel order of this dataset, to multiply with trial matrix

if length(clvalue) == 1
    m2 = zeros(size(m1)); %fake zeros matrix
    m3 = zeros(size(m1));
elseif length(clvalue) == 2
    cl2 = values == clvalue(2);
    m2 = cl2(ord,:); %
    m3 = zeros(size(m1));
elseif length(clvalue) == 3
    cl2 = values == clvalue(2);
    cl3 = values == clvalue(3);
    m2 = cl2(ord,:); % reoder mask according to channel order of this dataset
    m3 = cl3(ord,:); % reoder mask according to channel order of this dataset
end

% imagesc(m1)
%   yticks(1:28);
% yticklabels(label);
% figure
% imagesc(cl1)
%   yticks(1:28);
% yticklabels(order_chan);


Matrix = zeros(length(data_forlme.trial), 11);
count = 1;
for j = 1: length(data_forlme.trial)
    % prepare table with Pred Acc for stats lme
    Matrix(count,1) = sbj;                                          %subj
    Matrix(count,2) = data_forlme.trialinfo(j,3);                   %session
    Matrix(count,3) = data_forlme.trialinfo(j,5);                   %cond S- 1 S + 2
    Matrix(count,4) = data_forlme.trialinfo(j,7);                   %ITI
    Matrix(count,5) = data_forlme.trialinfo(j,8);                   %IOI
    Matrix(count,6) = data_forlme.trialinfo(j,6);                   %Surprise overall
    Matrix(count,7) = data_forlme.trialinfo(j,2);                   %melodyID
    x = data_forlme.trial{j}.*m1;
    dv = trapz(mean(x,1)); %average over chann and then integral over time ponts
    Matrix(count,8) = dv;                                           %DV P1
    x = data_forlme.trial{j}.*m2;
    dv = trapz(mean(x,1)); %average over chann and then integral over time ponts
    Matrix(count,9) = dv;                                           %DV N100
    x = data_forlme.trial{j}.*m3;
    dv = trapz(mean(x,1)); %average over chann and then integral over time ponts
    Matrix(count,10) = dv;                                          %DV P200
    Matrix(count,11) = data_forlme.trialinfo(j,4);                          %N note
    Matrix(count,12) = data_forlme.trialinfo(j,9);                          % Sp
    Matrix(count,13) = data_forlme.trialinfo(j,10);                          % So
    count = count +1;
end
Matrixintegrale = Matrix;


Matrix = zeros(length(data_forlme.trial), 11);
count = 1;
for j = 1: length(data_forlme.trial)
    % prepare table with Pred Acc for stats lme
    Matrix(count,1) = sbj;                                          %subj
    Matrix(count,2) = data_forlme.trialinfo(j,3);                   %session
    Matrix(count,3) = data_forlme.trialinfo(j,5);                   %cond S- 1 S + 2
    Matrix(count,4) = data_forlme.trialinfo(j,7);                   %ITI
    Matrix(count,5) = data_forlme.trialinfo(j,8);                   %IOI
    Matrix(count,6) = data_forlme.trialinfo(j,6);                   %Surprise overall
    Matrix(count,7) = data_forlme.trialinfo(j,2);                   %melodyID
    x = data_forlme.trial{j}.*m1;
    dv = mean(mean(x,1)); %average over chann and then integral over time ponts
    Matrix(count,8) = dv;                                           %DV P1
    x = data_forlme.trial{j}.*m2;
    dv = mean(mean(x,1)); %average over chann and then integral over time ponts
    Matrix(count,9) = dv;                                           %DV N100
    x = data_forlme.trial{j}.*m3;
    dv = mean(mean(x,1)); %average over chann and then integral over time ponts
    Matrix(count,10) = dv;
    Matrix(count,11) = data_forlme.trialinfo(j,4);                          %N note
    Matrix(count,12) = data_forlme.trialinfo(j,9);                          % Sp
    Matrix(count,13) = data_forlme.trialinfo(j,10);                          % So
    count = count +1;
end
Matrixmean = Matrix;

end