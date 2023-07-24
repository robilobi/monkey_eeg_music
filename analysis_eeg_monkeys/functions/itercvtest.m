function [stats,mdl] = itercvtest(stim,eeg,Fs,dir,minlag,maxlag,lambdas)
% Iteratively 1) leave each trial out, 2) run mTRFcrossval on all other trials,
% 3) compute the model on all other trials, and 4) test the model on the
% left-out trial from (1)

ntr = length(eeg); % get the number of trials
nchan = size(eeg{1},2); % get the number of EEG channels

cv_r = NaN(length(lambdas),ntr);
opt_lmb = NaN(ntr,1);
r_test = NaN(ntr,nchan);
mse_test = NaN(ntr,nchan);
mdl = cell(ntr,1);
for n = 1:ntr
    fprintf('** Test trial %d/%d **\n',n,ntr);

    test_tr = n; % get the testing trial
    % get the trials for training & crossvalidation
    train_tr = setxor(1:ntr,n);

    % Run crossvalidation on training trial, test on testing trial
    [r_test(n,:),mse_test(n,:),cv_r(:,n),opt_lmb(n),mdl{n}] = ...
        cv_then_test(stim,eeg,train_tr,test_tr,Fs,dir,minlag,maxlag,lambdas);
end

% Save the stats
stats.cv_r = cv_r;
stats.opt_lmb = opt_lmb;
stats.r_test = r_test;
stats.mse_test = mse_test;