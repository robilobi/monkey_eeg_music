function [r_test,mse_test,cv_r,opt_lmb,mdl] = cv_then_test(stim,eeg,train_tr,test_tr,Fs,dir,minlag,maxlag,lambdas)
% Run cross-validation on training trials, and test on the testing trials
% specified

% Run crossvalidation, AM model
stats = mTRFcrossval(stim(train_tr),eeg(train_tr),Fs,dir,minlag,maxlag,lambdas,'verbose',0);
% average over channels and CV trials
cv_r = mean(mean(stats.r,3),1)';
% identify the optimal lambda
opt_idx = find(cv_r==max(cv_r),1,'first'); % if multiple lambdas have identical performance, pick the smallest lambda
opt_lmb = lambdas(opt_idx);
% fit the model on all training trials
mdl = mTRFtrain(stim(train_tr),eeg(train_tr),Fs,dir,minlag,maxlag,opt_lmb);
% test on the left-out testing trial
[~,st_test] = mTRFpredict(stim(test_tr),eeg(test_tr),mdl);
r_test = st_test.r;
mse_test = st_test.err;