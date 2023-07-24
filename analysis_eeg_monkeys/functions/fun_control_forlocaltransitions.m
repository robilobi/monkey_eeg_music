function [allinfo] = fun_control_forlocaltransitions(typeofctrl,allinfo, idxSurprise)
% allinfo [all_id allpitches allonsets alliti allioi S Sp So Ep Eo];
% allinfo    1       2         3         4     5     6  7  8
%typeofctrl = 'ITI'; % 'IOI'
%idxSurprise = 1, 2 o 3 as to indicate Sall, Spitch, or Sonset (the column
%6,7,8 of allinfo matrix)

switch (typeofctrl)
    case 'noCtrl'
        %%% GET CONDITION H VS L IC
        surprise = allinfo(:,6:8);   % S Sp and So values are the col 6:8
        svect = surprise(:, idxSurprise); 
        Q    = quantile(svect,5);% IC 20% quantiles %use S overall 20 %for main anaysis, and Sp or So
        idx1 = (svect < Q(1));    % LOWEST IC
        allinfo(idx1,11) = 1;
        idx2 = (svect > Q(5));    % HIGHEST IC
        allinfo(idx2,11) = 2;
        allinfo(allinfo(:,4) == 99, 11) = 0;
  
%         %%% GET CONDITION H VS L IC
%         surprise = allinfo(:,end-2:end);   % S Sp and So values are the last 3 col
%         Q    = median(surprise(:,1));% IC 50% 
%         idx1 = (surprise(:, 1) < Q(1));    % LOWEST IC
%         allinfo(idx1,9) = 1;
%         idx2 = (surprise(:, 1) > Q(1));    % HIGHEST IC
%         allinfo(idx2,9) = 2;
%         allinfo(:,10) = 99;
%         allinfo(allinfo(:,4) == 99, 9) = 0;

    case 'ITI'
        %%% GET CONDITION H VS L IC WITHIN EACH INTERVAL SIZE
        surprise = allinfo(:,end-2:end);   % S Sp and So values are the last 3 col
        unique_int = unique(allinfo(:,4));
        for i = 2:length(unique_int) % do not consider the first note (-4)
            int = unique_int(i);
            current_interval= find(allinfo(:,4)==int);         %take values at the onsets
            Q    = quantile(surprise(int, 2),4);   % IC 25% quantiles
            idx1 = (allinfo(:,4)==int & allinfo(:,7) < Q(1));   % LOWEST IC
            allinfo(idx1,11) = 1;
            idx2 = (allinfo(:,4)==int & allinfo(:,7) > Q(4));   % HIGHEST IC
            allinfo(idx2,11) = 2;
        end
        allinfo(:,10) = 99;

    case 'IOI'

        %%% GET CONDITION H VS L IC WITHIN EACH IOI
        surprise = allinfo(:,end-2:end);   % S Sp and So values are the last 3 col
        unique_int = unique(allinfo(:,5));
        for i = 2:length(unique_int) % do not consider the first note (-4)
            int = unique_int(i);
            current_interval= find(allinfo(:,5)==int);          %take values at the onsets
            Q    = quantile(surprise(int, 3),4);   % IC 25% quantiles
            idx1 = (allinfo(:,5)==int & allinfo(:,8) < Q(1));   % LOWEST IC
            allinfo(idx1,11) = 1;
            idx2 = (allinfo(:,5)==int & allinfo(:,8) > Q(4));   % HIGHEST IC
            allinfo(idx2,11) = 2;
        end
        allinfo(:,10) = 99;

    case 'ITOI'
        idx = allinfo(:,4) == -4; %% THIS IS FIRST MEL NOTES
        allinfo2= allinfo;
        allinfo2(idx,:) = [];

        iti = allinfo2(:,4);
        ioi = allinfo2(:,5);
        mediti = median(iti);
        medioi = median(ioi);

        idx1 = (allinfo(:,4) < mediti & allinfo(:,5) < medioi);
        idx2 = (allinfo(:,4) >=mediti & allinfo(:,5) < medioi);
        idx3 = (allinfo(:,4) < mediti & allinfo(:,5) >=medioi);
        idx4 = (allinfo(:,4) >=mediti & allinfo(:,5) >=medioi);
        allinfo(idx1,12) = 1;
        allinfo(idx2,12) = 2;
        allinfo(idx3,12) = 3;
        allinfo(idx4,12) = 4;

        for i = 1:4
            idx = allinfo(:,10)== i;
            Q    = quantile(allinfo(idx, 6),3);   % IC 25% quantiles
            idx1 = (allinfo(:,12) ==i & allinfo(:,6) <= Q(1));
            idx2 = (allinfo(:,12) ==i & allinfo(:,6) >= Q(3));
            allinfo(idx1,11) = 1;
            allinfo(idx2,11) = 2;
        end
        idx = allinfo(:,4) == -4; %% THIS IS FIRST MEL NOTES
        allinfo(idx,11) = 0;
        allinfo(idx,12) = 0;

end

    allinfo(allinfo(:,4) == 99, 9) = 0; %% REMOVE ALL first notes per each melody
    c1= find(allinfo(:,11)==1); %take values at the onsets
    c2= find(allinfo(:,11)==2); %take values at the onsets
    disp(['........ Selected notes ' num2str(numel(c1)) ' COND1 and ' num2str(numel(c2)) ' COND2']);


%     %%% PLOT HISTOGRAM OF ITI AND IOI OF SELECTED NOTES
%     x1 = allinfo(c1,4);
%     x2 = allinfo(c2,4);
%     figure; subplot(1,2,1); h1 = histogram(x1); hold on; histogram(x2,h1.BinEdges); hold off
%     legend('Low', 'High');title('ITI distribution' );
%     ylabel('Occurrences'); xlabel('Type of ITI (semitones)');
%     % [~, p, ~] = kstest2(x1,x2); txt = {'Ks p-value =' num2str(round(p))};text(20,70,txt)
%     % [~, p] = ttest2(x1,x2); txt = {'p-value =' num2str(round(p))};text(20,70,txt)
% 
%     x1 = allinfo(c1,5);
%     x2 = allinfo(c2,5);
%     subplot(1,2,2); h1 = histogram(x1); hold on; histogram(x2,h1.BinEdges); hold off
%     legend('Low', 'High');title('IOI distribution' );
%     ylabel('Occurrences'); xlabel('Type of IOI (sec)');
%     % [~, p, ~] = kstest2(x1,x2); txt = {'Ks p-value =' num2str(round(p))};text(0.3,300,txt)
%     % [~, p] = ttest2(x1,x2); txt = {'p-value =' num2str(round(p))};text(0.3,300,txt);
% 
%     saveas(gcf, [filename '.png']);


end
