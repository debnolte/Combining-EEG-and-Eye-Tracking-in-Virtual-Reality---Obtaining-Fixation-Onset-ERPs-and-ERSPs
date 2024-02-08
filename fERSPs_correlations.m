%% to restart everything
clear variables
close all;
clc;

cond = 'dd'; 

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
% load Fieldtrip
addpath('.../Matlab-resources/fieldtrip-20230215');
ft_defaults

%% get subjects to include 
subjects = [1,2,5,7,12,17,18,19,20,21,22,27,29,30,32,33,34,37,38,];

%% 
% loop through all subjects
for sub = 3:length(subjects)
    % get subject number
    s = subjects(sub);
    % load the preprcoessed data
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
        % epoch the data (longer epochs because of ERSPs)
        EEG = pop_epoch(EEG, {}, [-0.875 1.175]);
        EEG = eeg_checkset(EEG); 

        %% converting the data set from eeglab into fieldtrip structure
        EEG_ft = eeglab2fieldtrip(EEG, 'raw', 'coord_transform');
        clear EEG
        %% calculate the ERSP across trials
        % only do this for the no-shift condition
        if i == 1
              % create cfg for time-frequency analysis
              cfg = [];
              cfg.channel    = 'Oz';
              cfg.method     = 'wavelet';
              cfg.output     = 'pow';
              cfg.width      = 3;
              cfg.toi        = linspace(min(EEG_ft.time{1,1}),max(EEG_ft.time{1,1}), length(EEG_ft.time{1,1})); %matching data points in time depending on min and max in time in equal length
              cfg.foi        = 1:0.5:45;
              cfg.pad        = 'nextpow2';
              % ERSP for al trials of one subject
              avg_ersp = ft_freqanalysis(cfg, EEG_ft);
        end 

        %% calculate ERSP for each trial

        % time-frequency analysis
        % but during this analaysis we save it for each trial
        cfg = [];
        cfg.channel    = 'Oz';
        cfg.method     = 'wavelet';
        cfg.output     = 'pow';
        cfg.width      = 3;
        cfg.toi        = linspace(min(EEG_ft.time{1,1}),max(EEG_ft.time{1,1}), length(EEG_ft.time{1,1})); %matching data points in time depending on min and max in time in equal length
        cfg.foi        = 1:0.5:45;
        cfg.pad = 'nextpow2';
        cfg.trials = 'all'; % keep all trials
        cfg.keeptrials = 'yes';

        freqResults = ft_freqanalysis(cfg, EEG_ft);


        %% Compute the correlation
        % for the no-shift condition: 
        if i == 1
            % get the number of trials
            trialCount = size(freqResults.powspctrm);
            trialCount = trialCount(1); 
            % create an empty matrix to save the coefficients
            corr_coef = zeros(3,trialCount);
        end

        % time window we want to analyse (short window to match the ERPs)
        indexStart = 347;
        indexEnd = 705;

        % create single trial ERSP matrix for short time window (-200 500) 
        % with three dimensions instead of the four orginially
        single_trial_ersp_matrix = squeeze(freqResults.powspctrm);
        single_trial_ersp_matrix_cut = single_trial_ersp_matrix(:,:, indexStart:indexEnd);

        % create average ERSP matrix for short time window (-200 500) with
        % two dimensions
        avg_ersp_matrix = squeeze(avg_ersp.powspctrm(:,:,:));
        avg_ersp_matrix_cut = avg_ersp_matrix(:, indexStart:indexEnd);

        % loop through all trials
        for trialIndex = 1:trialCount
            tr = size(freqResults.powspctrm);
            if trialIndex < tr(1)
                % select data for current trial of interest from the matrix
                % this leaves us with a two dimensional matrix as the avg_ersp
                single_trial_ersp = squeeze(single_trial_ersp_matrix_cut(trialIndex,:,:));

                %calculate correlation between avg ERSP and each single trial ERSP
                R = corrcoef(avg_ersp_matrix_cut, single_trial_ersp,'Rows','complete');
                corr_coef(i,trialIndex) = R(1,2);
            end
        end

     end

    %% Save the correlation data
    save(fullfile(savepath,sprintf('correlation_shift_ERSP_%s_%u.mat',cond,s)),'corr_coef');

end
