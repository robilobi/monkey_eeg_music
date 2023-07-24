function fun_clusterBasedPermutation_Plot(stat,saveaspng, title,plot_type, data_type, layfile)
switch(data_type)
    case 'mean'
        limits = [-0.2 0.2];
    case 't_value'
        limits = [-10,10];
    case 'F_value'
        limits = [-6 6];
    case 'p_value'
        limits = [0 1];
end
load(layfile);
order_chan = lay.label;

switch(plot_type)
    case 'topoplots'
        [~,f_name] = fileparts(saveaspng);
        title = f_name;
        cfg = [];
        cfg.highlightsymbolseries = ['*','*','.','.','.'];
        cfg.highlightseries = {'on', 'on', 'off', 'off', 'off'};
        cfg.layout = lay;
        cfg.contournum = 0;
        cfg.markersymbol = '.';
        cfg.alpha            = 0.025; %https://www.fieldtriptoolbox.org/tutorial/cluster_permutation_timelock/#the-format-of-the-output
        % a p-value less than the critical alpha-level of 0.025. This critical alpha-level corresponds to a false alarm rate of 0.05 in a two-sided test.
        cfg.parameter='stat';
        cfg.zlim = [-6 6];
        cfg.saveaspng = saveaspng;
        cfg.dataname = title;
        cfg.colormap = 'RdBu';
        try
            ft_clusterplot(cfg, stat);
            ft_colormap('RdBu');
            colormap(flipud(brewermap(64,'RdBu')));

        catch

            [~,f_name] = fileparts(saveaspng);
            disp(['failed plot ' f_name]);
        end

    case 'images'
        [root_dir,f_name] = fileparts(saveaspng);
        data = stat.stat;
        title = strrep(title,'cluster_plot_','cluster_plot_images_');
        mask = {stat.mask};

        % IBS_plot_correlation_map(stat.stat,title,'images','F_value','',[],root_dir,varargin_table)
        h=figure;clf
        h.Position = [100 100 800 700];
        current_label = stat.label;
        %         frontal_first_chan = cat(1,label(contains(label,'F')),label(~contains(label,'F')));
        [a, frontal_order] = ismember(order_chan, current_label);

        if strcmp(data_type,'t_value')
            values_to_zero = (data <2 & data > -2);
            data(values_to_zero) = 0;
        end
        imagesc(data(frontal_order,:),limits);colorbar;
        yticks(1:size(data,1));
        yticklabels(order_chan);
        xticks(1:size(stat.time,2))
        xticklabels(stat.time);
        ax = gca;
        labels = string(ax.XAxis.TickLabels); % extract
        labels(2:2:end) = nan; % remove every other one
        ax.XAxis.TickLabels = labels; % set
        colormap(flipud(brewermap(64,'RdBu')));

        try
            [y,x] = find(mask{1}(frontal_order,:));
            %[y,x] = find(mask{1});
            hold on;scatter(x,y,'*','k')
        catch
        end
        ax = gca;
        ax.XAxis.FontSize = 14;
        ax.YAxis.FontSize = 14;
        saveas(gcf, [saveaspng '.png']);
        %exportgraphics(ax,[root_dir filesep title '_' data_type '_' plot_type '_stat_int_rev.png'],'BackgroundColor','none','ContentType','vector')
end
end

