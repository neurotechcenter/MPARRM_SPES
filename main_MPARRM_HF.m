% Tao Xie Mar/24/2022

clc,clear;
addpath(genpath('code/MP_master'))    % matching pursuit method
addpath('code/eeglab2022.0_simplify')
addpath('code')
eeglab; close all; clear;

%% import data into EEGlab
% load the raw data
load('sample data/sample_HF.mat','inEEG')
if inEEG.nbchan ~= size(inEEG.data,1); error('The number of channels is not correct!'); end
if length(inEEG.trigOnset) ~= length(inEEG.trigType); error('The number of trigger is not correct!'); end

% import the raw data into EEGLAB
dat = inEEG.data;
EEG = pop_importdata('subject',    'Subject1',  ...
                     'condition',  'HF',      ...
                     'data',       'dat',       ...
                     'srate',      inEEG.srate, ...
                     'nbchan',     inEEG.nbchan,...
                     'dataformat', 'array');
for ch = 1:EEG.nbchan
    EEG.chanlocs(ch).labels = ['ELE' num2str(ch)];
end

% import the trigger event into eeglab
fp = fopen('code/eventtable.txt','w');
for s = 1:length(inEEG.trigOnset)
    fprintf(fp,'%20s %20d\n',inEEG.trigType{s},inEEG.trigOnset(s));
end
fclose(fp);
EEG = pop_importevent( EEG,                                ...
                       'event',    'code/eventtable.txt',  ...
                       'fields',   {'type','latency'},     ...
                       'timeunit', nan);
EEG = eeg_checkset( EEG );
     
%% epoch the signal based on trialOnset
% you can ignore and run the MPARRM with un-epoched signal
EEG = pop_epoch(EEG,{'trialOnset'},[-1 2]);
figure;
plot(EEG.times,EEG.data(1,:,1));
xlabel('Time (ms)'); ylabel('Amplitude (uV)'); set(gca,'fontsize',14)

%% MPARRM
% this function can only be run on windows system
% the parameter related to MPARRM will be saved in "savePath" folder (e.g., "MP" in current folder)
% please delate "MP" folder if you want to run the MPARRM again
if ispc 
    [EEGclean,EEGart] = MPARRM(EEG,...
                               'stimType',      'pulseOnset',          ...
                               'centerTime',    1,                     ...
                               'winTimeLen',    8,                     ...
                               'minMPepochLen', 100,                   ...
                               'savePath',      'MP',                  ...
                               'saveName',      'sample_HF',         ...
                               'runIndivChan',  false);
    save('sample data/artFree_sample_HF.mat','EEG','EEGart','EEGclean'); 
    disp('MPARRM DONE!')
end

%% show results
load('sample data/artFree_sample_HF.mat','EEG','EEGart','EEGclean'); 
figure('position',[10 10 800 400]);
subplot(1,2,1);hold on;
plot(EEG.times,squeeze(EEG.data(1,:,1)),'k','linewidth',3);
plot(EEG.times,squeeze(EEGclean.data(1,:,1)),'r','linewidth',1);
xlim([-50 1100]); ylim([-500 4000]); 
xlabel('Time (ms)'); ylabel('Amplitude (uV)');
set(gca,'fontsize',14)


[pw,~] = pwelch(squeeze(EEG.data),EEG.srate,[],EEG.srate,EEG.srate);
[pwClean,f] = pwelch(squeeze(EEGclean.data),EEG.srate,[],EEG.srate,EEG.srate);

subplot(1,2,2); hold on;
plot(f,10*log10(mean(pw,2)),'k','linewidth',1)
plot(f,10*log10(mean(pwClean,2)),'r','linewidth',1)
xlim([0 500])
xlabel('Frequency (Hz)'); ylabel('Power (dB)');
set(gca,'fontsize',14)






