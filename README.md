# Combining EEG and Eye-Tracking in Virtual Reality - Obtaining Fixation-Onset ERPs and ERSPs

The project implemented and tested an eye-movement classification algorithm for data recorded in a 3d, free-viewing, and free-movement virtual environment. It is a velocity-based classification based on the algorithms of the MAD saccade (Keshava et al., 2023; Voloh et al., 2020) and REMoDNav (Dar et al., 2021). The code has been tested in combination with EEG data and can be used to generate fERPs and fERSPs. <br />
The scripts provided here include the classification algorithm itself, analysis scripts, and preprocessing scripts for both eye-tracking and EEG data. The corresponding data is available at the Center for Open Science https://osf.io/trfjw/, DOI 10.17605/OSF.IO/TRFJW.
<br />

## File overview
### 7v_ET_classification_algorithm.ipynb
This is the implementation of the eye-tracking algorithm. It classifies continuous eye-tracking data into gazes and saccades. The script concludes with the code used to generate trigger files for EEG. It can be run in chronological order. Depending on the input parameters, the beginning might require some adjustments. <br />
Input: 
- information on the validity of each sample
- 3d vector indicating the eye position
- the position of the objects hit by the ray cast of the eyes
- the name of the objects hit by the ray cast of the eyes
- additional parameters, such as head direction vectors, can be included <br />
Output:
* a label for each sample indicating if it is valid or not; if it belongs to a gaze or saccade; if it is an outlier
* the average duration of each event and distance towards the viewed objects
* EEG trigger files without (and with) a time shift

### 11v_figures.ipynb
This is the script used to plot all figures and to run all statistical tests presented in the corresponding publication. It requires the output of the eye-tracking algorithm and, in some cases, the output of the EEG analysis done in MatLab.

### 12_handLabeled.ipynb
This is the script used to correct for outliers in the hand-labeled data and compare the results with the algorithm. This file requires a hand-labeled data file and the algorithm's corresponding output. It generates plots and a short analysis to compare the two classifications.

### 0v_generate_file_overview.ipynb, 1v_preprocesses_timestamps.ipynb, 2v_combine_files_subj8.ipynb, 3v_check_task_instructions.ipynb
These files are the preprocessing scripts for the eye-tracking data gathered in Unity and recorded using LSL. File “_3v_check_task_instructions.ipynb_” additionally filters out subjects that moved away from the main square too often. The files use the raw data files as input and generate a .csv file summarizing the data suitable for further analysis and .csv files of all recorded data corrected and aligned.

### fERPs_figures_correlation.m
The MatLab will load the preprocessed EEG files, compute the fERP for each subject, and plot additional figures. Furthermore, it computes the correlation between each trial and the average ERP.

### fERSPs_figures.m
This file will load in the preprocessed EEG files, compute fERSPs, and generate results figures.

### fERSPs_correlations.m 
This is used to compute the correlation between each individual trial and the average ERSP for each subject.
<br />
<br />
<br />
## References
Dar, Asim H., Wagner, Adina S., & Hanke, Michael. (2021). REMoDNaV: robust eye-movement classification for dynamic stimulation. Behavior Research Methods, 53(1), 399–414.  <br />
<br />
Keshava, A., Gottschewsky, N., Balle, S., Nezami, F. N., Schüler, T., & König, P. (2023). Action affordance affects proximal and distal goal-oriented planning. European Journal of Neuroscience, 57(9), 1546–1560. https://doi.org/10.1111/ejn.15963 <br />
<br />
Voloh, B., Watson, M. R., Konig, S., & Womelsdorf, T. (2020). MAD saccade: Statistically robust saccade threshold estimation via the median absolute deviation. Journal of Eye Movement Research, 12(8). https://doi.org/10.16910/jemr.12.8.3 
