%% creating two ERSP plots for the paper 

% one plot will show an ERSP spectrogram for one specific participant 
% (Subject 1) and the other one will show it for all participants 

%% to restart everything
% % do not run when running it automatically
clear variables
close all;
clc;
%% Load necessary code
% paths to store the plots in
basepath='.../MatlabCode';
cd(basepath);

% path where the variables/output are stored
savepath = '.../data/processed/EEG';
addpath('.../data/processed/EEG');
% load EEGlab
addpath('.../Matlab-resources/eeglab2020_0');
eeglab;

%% get subjects to include
subjects = [1,2,5,7,12,17,18,19,20,21,22,27,29,30,32,33,34,37,38,];
%% 
% variable to store the data for all subjects
data_all = [];

%% for loop: load individual subjects
for s = 1:length(subjects)
    % get the subject number
    s = subjects(sub);
    % load the preprocessed EEG data
    EEG = pop_loadset(sprintf('new_full_data_%s.set',s),savepath);
    EEG = eeg_checkset(EEG);
    % Epoch the data
    EEG_epoched = pop_epoch(EEG, {}, [-0.875 1.175], 'epochinfo', 'yes');
    clear EEG % to save space
    %% transfrom the first dataset into fieldtrip to be used for the layout later on:
    if s == 1
        % save the dataset
        pop_saveset(EEG_epoched,'filename','epoched_for_layout','filepath',savepath);
        % load it into ft_preprocessing
        cfg         = [];
        cfg.dataset = fullfile(savedata_epoch,'epoched_for_layout.set');
        data_ft     = ft_preprocessing(cfg);
        
        % compute the frequency spectrum
        cfg         = [];
        cfg.channel = 'all';
        cfg.method  = 'wavelet';
        cfg.output  = 'pow';
        cfg.width   = 3;
        cfg.toi     = linspace(min(data_ft.time{1,1}),max(data_ft.time{1,1}), length(data_ft.time{1,1})); %matching data points in time depending on min and max in time in equal length
        cfg.foi     = 1:0.5:45;
        cfg.pad     = 'nextpow2';
        TFRwave     = ft_freqanalysis(cfg, data_ft);
        % save the output 
        save(fullfile(savepath,'TFRwave.mat'),TFRwave);
    end
    %% create one file with all subject data while looping
    % in the first loop the data_all is still empty 
    % we go into the first statement and also save the data for subj 1
    if isempty(data_all)
        data_all = EEG_epoched;
        data_subj_1 = EEG_epoched;
    % afterwards, we combine the datasets
    else
        data_all = pop_mergeset(data_all, EEG_epoched);
    end

    clear EEG_epoched  % to save space
end
% save the files (they are rather big)
save(fullfile(savepath,'data_all_ersp.mat'),'data_all','data_subj_1','-v7.3');
%%
% load the data if needed
load([savepath '/data_all_ersp.mat']);

%% converting the the two data sets from EEGlab into Fieldtrip
data_all_ft = eeglab2fieldtrip(data_all, 'raw', 'coord_transform'); % all subjects
data_subj_1_ft = eeglab2fieldtrip(data_subj_1, 'raw', 'coord_transform'); % single subject
% save the data
save(fullfile(savepath,'data_all_ersp_fieldtrip.mat'),'data_all_ft','data_subj_1_ft','-v7.3');
 
%% Using morlet wavelets for time-frequency analyis
% with a cycle number of 3 and frequencies from 1-45 Hz

% load the data if needed
load([savepath '/data_all_ersp_fieldtrip.mat']); 
%% Compute the frequency analysis - takes some time
% prepare cfg
cfg            = [];
cfg.channel    = 'all';
cfg.method     = 'wavelet';
cfg.output     = 'pow';
cfg.width      = 3;
cfg.toi        = linspace(min(data_all_ft.time{1,1}),max(data_all_ft.time{1,1}), length(data_all_ft.time{1,1})); %matching data points in time depending on min and max in time in equal length
cfg.foi        = 1:0.5:45;
cfg.pad = 'nextpow2';

% all subjects
TFRwave_all = ft_freqanalysis(cfg, data_all_ft);
save(fullfile(savepath,'TFRwave_all.mat'),'TFRwave_all','-v7.3');

% single Subject (participant 1)
TFRwave_single_subj = ft_freqanalysis(cfg, data_subj_1_ft);
save(fullfile(savepath,'TFRwave_single_subj.mat'),'TFRwave_single_subj','-v7.3');
%% Load the frequency data
load([savepath '/TFRwave_all.mat']);
load([savepath '/TFRwave_single_subj.mat']);

%% Plotting -- all subjects
cfg                 = [];
cfg.baseline        = [-0.5 -0.2]; % (keeping the average saccade duration out of the baseline)
cfg.baselinetype    = 'db';
cfg.marker          = 'on';
cfg.parameter       = 'powspctrm';
cfg.colorbar        = 'yes';
cfg.xlim            = [-0.5 0.8];
cfg.ylim            = [2 45];
cfg.zlim            =  [-0.8 0.8];
cfg.layout          = 'ordered'; 
cfg.channel         = 'Oz'; 
cfg.colormap        = '*RdBu';

% plotting
figure;
ft_singleplotTFR(cfg, TFRwave_all);

title('   '); % we don't want to include a title
% plot a line at gaze onset
xlin = xline(0,'k--');
xlin.LineWidth = 2;
xlin.Alpha = 1;
% add a colorbar
c = colorbar;
c.Ticks =  [-0.8 -0.4 0 0.4 0.8];
c.FontSize = 14;
set(gca,'fontname','arial')
ax = gca;
ax.FontSize = 16;
yticks([5 15 25 35 45])
xticklabels({'-500','0','500'})
xticks([-0.5 0 0.5])
% plot a recatnge to highlight the baseline period
rectangle('position',[-0.5 1.8 0.35 43.4], 'FaceColor',[0, 0, 0, 0.1]);

% Save plot 
file_name = 'NEW_ERSP_at_Oz_all_Subject_fin.png';
file_path = fullfile(savepath, file_name);
saveas(gcf, file_path);

%% Plotting -- single subject
% set up cfg again 
cfg                 = [];
cfg.baseline        = [-0.5 -0.2]; % (keeping the average saccade duration out of the baseline)
cfg.baselinetype    = 'db';
cfg.marker          = 'on';
cfg.parameter       = 'powspctrm';
cfg.colorbar        = 'yes';
cfg.xlim            = [-0.5 0.8];
cfg.ylim            = [2 45];
cfg.zlim            =  [-0.8 0.8];
cfg.layout          = 'ordered'; 
cfg.channel         = 'Oz'; 
cfg.colormap        = '*RdBu';

figure;
ft_singleplotTFR(cfg, TFRwave_single_subj);
title('   ');
% draw a line at gaze onset
xlin = xline(0,'k--');
xlin.LineWidth = 2;
xlin.Alpha = 1;
% set up colorbar
c = colorbar;
c.Ticks =  [-0.8 -0.4 0 0.4 0.8];
c.FontSize = 14;
set(gca,'fontname','arial')
ax = gca;
ax.FontSize = 16;
yticks([5 15 25 35 45])
xticklabels({'-500','0','500'})
xticks([-0.5 0 0.5])
% draw a rectangle to highlight the baseline
rectangle('position',[-0.5 1.8 0.35 43.4], 'FaceColor',[0, 0, 0, 0.1]);

% Save plot from single subjects
file_name = 'NEW_ERSP_at_Oz_single_Subject_fin.png';
file_path = fullfile(savepath, file_name);
saveas(gcf, file_path);
%% Topoplots: first time interval
% prepare the layout:
load(fullfile(savepath,'TFRwave.mat'));
cfg     = [];
layout  = ft_prepare_layout(cfg, TFRwave);

% prepare cfg
cfg                 = [];
cfg.layout          = layout;
cfg.baseline        = [-0.5 -0.2];
cfg.comment         = 'no';
cfg.baselinetype    = 'db';
cfg.colorbar        = 'yes';
cfg.colormap        = '*RdBu';
cfg.parameter       = 'powspctrm';
cfg.xlim            = [0 0.15]; % time interval
cfg.ylim            = [4 15];
cfg.zlim            = [-0.8 0.8]; 

% plot all subjects
ft_topoplotTFR(cfg, TFRwave_all);
c = colorbar;
c.Ticks =  [-0.8 -0.4 0 0.4 0.8];
c.FontSize = 14;
set(gca,'fontname','arial')
% Save plot from all subjects
file_name = 'NEW_Topoplot_all_Subject_0-0.15s_fin.png';
file_path = fullfile(savepath, file_name);
saveas(gcf, file_path);

% plot single subject
ft_topoplotTFR(cfg, TFRwave_single_subj);
c = colorbar;
c.Ticks =  [-0.8 -0.4 0 0.4 0.8];
c.FontSize = 14;
set(gca,'fontname','arial')
% Save plot from all subjects
file_name = 'NEW_Topoplot_sinlge_Subject_0-0.15s_fin.png';
file_path = fullfile(savepath, file_name);
saveas(gcf, file_path);

%% Topoplots: second time interval
% prepare the layout:
load(fullfile(savepath,'TFRwave.mat'));
cfg     = [];
layout  = ft_prepare_layout(cfg, TFRwave);

% prepare cfg
cfg                 = [];
cfg.layout          = layout;
cfg.baseline        = [-0.5 -0.2];
cfg.comment         = 'no';
cfg.baselinetype    = 'db';
cfg.colorbar        = 'yes';
cfg.colormap        = '*RdBu';
cfg.parameter       = 'powspctrm';
cfg.xlim            = [0.16 0.3]; % time interval
cfg.ylim            = [4 15];
cfg.zlim            = [-0.8 0.8]; 

% all subjects
ft_topoplotTFR(cfg, TFRwave_all);
c = colorbar;
c.Ticks =  [-0.8 -0.4 0 0.4 0.8];
c.FontSize = 14;
set(gca,'fontname','arial')
% Save plot from all subjects
file_name = 'NEW_Topoplot_all_Subject_0.16-0.3s_fin.png';
file_path = fullfile(savepath, file_name);
saveas(gcf, file_path);

% single subject
ft_topoplotTFR(cfg, TFRwave_single_subj);
c = colorbar;
c.Ticks =  [-0.8 -0.4 0 0.4 0.8];
c.FontSize = 14;
set(gca,'fontname','arial')
% Save plot from all subjects
file_name = 'NEW_Topoplot_single_Subject_0.16-0.3s_fin.png';
file_path = fullfile(savepath, file_name);
saveas(gcf, file_path);