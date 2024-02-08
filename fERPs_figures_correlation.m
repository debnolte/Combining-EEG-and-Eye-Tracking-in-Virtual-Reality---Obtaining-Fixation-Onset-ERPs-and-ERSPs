%% to restart everything
clear variables
close all;
clc;

cond = 'dd'; 

% set the ones to true that should be plotted
erp = true;
correlation = false;
multiplot = false;
topoplot = false;
%% Load necessary code
% paths to store the plots in
basepath='.../MatlabCode';
cd(basepath);

savepath = '.../data/processed/EEG';
addpath('.../data/processed/EEG');

addpath('.../Matlab-resources/eeglab2020_0');
eeglab;
%% get subjects to include 
subjects = [1,2,5,7,12,17,18,19,20,21,22,27,29,30,32,33,34,37,38,];

%% %%%%%%%%%%%%%%%%%%% AVG ERPs %%%%%%%%%%%%%%%%%%%%%%%%%
% save them for plotting in python
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if erp
    avg_erps_no = zeros(length(subjects),358); % empty to save avg erps
    nr_events = zeros(length(subjects),1); % empty to save nr of trials per condition
    %%
    for sub = 1:length(subjects)
        % get the subject number
        s = subjects(sub);
        % load the preprocessed EEG data
        EEG = pop_loadset(sprintf('new_full_data_%s.set',s),savepath);

        % epoch the data
        EEG = pop_epoch(EEG, {}, [-0.2 0.5]);
        EEG = eeg_checkset(EEG); 
        EEG_data = EEG.data(:,:,:); % for shorter code

        % select the correct electrode and find the index
        currElec = 'Oz';
        el_idx = find(strcmp({EEG.chanlocs.labels}, currElec) == 1); % find the index of electrode
        % manually calculate the mean across all trials
        EEG.mean = mean(EEG_data, 3);

        % save the ERP for each subject for the selected electrode
        avg_erps_no(sub,:)   = EEG.mean(el_idx, :); 
        % save the number of events used to calculate the ERP
        nr_events(sub,1) = length(EEG.data);

    end

    % save the results
    times = EEG.times;
    save(fullfile(savepath,'avg_erps.mat'),'avg_erps_no', 'times');
    save(fullfile(savepath,'nr_trials_erp.mat'),'nr_events');
end
%%



%% %%%%%%%%%%%%%%%%%%% CORRELATION %%%%%%%%%%%%%%%%%%%%%%
% Compute the correlation between individual trials and the average ERP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if correlation
    %% for each subject:
    for sub = 1:length(subjects)
        % get the subject number
        s = subjects(sub);
        % load the preprocessed data
        EEG_no = pop_loadset(sprintf('new_full_data_%s.set',s),savepath);
        EEG_pos = pop_loadset(sprintf('new_full_data_%s_pos.set',s),savepath);
        EEG_neg = pop_loadset(sprintf('new_full_data_%s_neg.set',s),savepath);

        %% Filter and Epoch the data
        for i = 1:3
            % assign variable, so we only work with EEG from now on
            if i == 1
                EEG = EEG_no;
            elseif i == 2
                EEG = EEG_pos;
            else
                EEG = EEG_neg;
            end
            % filter the data
            EEG = pop_eegfiltnew(EEG, filt, []);
            % epoch the data
            EEG = pop_epoch(EEG, {}, [-0.2 0.5]);
            EEG = eeg_checkset(EEG); 
            EEG_data = EEG.data(:,:,:); % for shorter code
            % select the correct electrode and find the index
            currElec = 'Oz';
            el_idx = find(strcmp({EEG.chanlocs.labels}, currElec) == 1); %find the index of electrode

            % only for the no-shift condition:
            if i == 1
                % create empty matrix to save correlation coefficients
                corr_coef = zeros(3,length(squeeze(EEG.data(el_idx,:,:)))); 
            
                % calculate the average ERP and save it (for correlation)
                EEG.mean = mean(EEG_data, 3);
                avg_erp   = EEG.mean(el_idx, :); 
            end
            % only use the data from one electrode
            EEG_new = squeeze(EEG.data(el_idx,:,:)); 

            % go through each trial
            for tr = 1:length(EEG_new)
                % get the current trial
                trl = EEG_new(:,tr);
                % calculate the correlation between the current trial and
                % the average erp
                R = corrcoef(avg_erp,trl); 
                % save the results
                corr_coef(i,tr) = R(1,2);
            end

        end

        %% Save the correlation data
        % compute the mx and index of the max correlation coefficient
        [max_n,corr_count] = max(corr_coef);

        save(fullfile(savepath,sprintf('correlation_shift_%s_%u.mat',cond,s)),'corr_coef','corr_count');
    end
end
%%




%% %%%%%%%%%%%%%%%%%%% Multiplot %%%%%%%%%%%%%%%%%%%%%%%%
% Create a multiplot for one subject
% Important: the eeglab data has to be transfromed to fieldtrip for this
% code!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if multiplot
    % we will use fieldtrip for the following plots
    addpath('.../Matlab-resources/fieldtrip-20230215');
    ft_defaults
    
    % load the subejct (we only did it for one subject so it is hardcoded)
    uidname = '70656182-09b3-4c19-9ae2-0a2ab2e19fed';
    load([savepath ['data_eeg_fieldtrip_' uidname]]);

    % color used in all plots
    str = '#27408B';
    color = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;

    % plot the multiplot using ft_multiplotER
    cfg             = [];
    cfg.channel     = 'all';
    cfg.linewidth   = 1.0;
    cfg.linecolor   = color;
    cfg.showcomment = 'no';
    cfg.showscale   = 'no';
    figure; ft_multiplotER( cfg, data_eeg);
    titleStr = 'Topoplot_ERPs';
    % save the figure
    set(gcf, 'PaperOrientation', 'landscape')
    print(gcf,fullfile(savepath,[titleStr '.png']),'-dpng','-r500')

end
%%




%% %%%%%%%%%%%%%%%%%%% Topoplot %%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if topoplot
    % we will use fieldtrip for the following plots
    addpath('.../Matlab-resources/fieldtrip-20230215');
    ft_defaults
    
    % load the subejct (we only did it for one subject so it is hardcoded)
    uidname = '70656182-09b3-4c19-9ae2-0a2ab2e19fed';
    load([savepath ['data_eeg_fieldtrip_' uidname]]);
    
    % set time windows to average over 
    limits = [[0.0 0.02];[0.08 0.1];[0.15 0.17];[0.28 0.3]];
    % create 4 plots (over 4 different time windows)
    for i = 1:4
        % plot the data using ft_topoplotER
        cfg = [];
        cfg.xlim = limits(i,:);
        cfg.zlim = [-2.4 2.4];
        cfg.comment = 'no';
        cfg.colormap = '*RdBu';
        cfg.colorbar = 'yes';
        figure; ft_topoplotER(cfg,data_eeg);
        % set the colorbar
        c = colorbar;
        c.Ticks =  [-2 -1 0 1 2];
        c.FontSize = 14;
        set(gca,'fontname','arial')
        titleStr = strcat('Topoplot_col_',string(cfg.xlim(1)),'.png');
        % save the plot
        set(gcf, 'PaperOrientation', 'landscape')
        saveas(gcf,fullfile(savedata_repo,titleStr))
    end
end
%%
