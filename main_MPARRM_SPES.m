% Tao Xie Mar/24/2022

clc,clear;
addpath(genpath('code/MP_master'))    % matching pursuit method
addpath('code/eeglab2022.0_simplify')
addpath('code')
eeglab; close all; clear;

%% import data into EEGlab
% load the raw data
load('sample data/sample_SPES.mat','inEEG')
if inEEG.nbchan ~= size(inEEG.data,1); error('The number of channels is not correct!'); end
if length(inEEG.trigOnset) ~= length(inEEG.trigType); error('The number of trigger is not correct!'); end

% import the raw data into EEGLAB
dat = inEEG.data;
EEG = pop_importdata('subject',    'Subject1',  ...
                     'condition',  'SPES',      ...
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
     
%% remove the ERP component
% epoch the signal
EEG = pop_epoch(EEG,{'pulseOnset'},[-0.5 0.5]);

% show raw signal
figure('position',[10 10 800 400]);
subplot(1,2,1);
plot(EEG.times,squeeze(EEG.data(1,:,:)));
xlim([-50 100]);xlabel('Time (ms)'); ylabel('Amplitude (uV)'); title('Raw Signal')
set(gca,'fontsize',14)

% substract ERP
for ch = 1:EEG.nbchan
    dat = squeeze(mean(EEG.data(ch,:,:),3))';
    EEG.data(ch,:,:) = detrend(squeeze(EEG.data(ch,:,:))-repmat(dat,1,EEG.trials));
end

% show signal after substraction
subplot(1,2,2);
plot(EEG.times,squeeze(EEG.data(1,:,:)));
xlim([-50 100]);xlabel('Time (ms)'); ylabel('Amplitude (uV)'); title('Raw Signal')
set(gca,'fontsize',14)

%% MPARRM
% this function can only be run on windows system
% the parameter related to MPARRM will be saved in "savePath" folder (e.g., "MP" in current folder)
% please delate "MP" folder if you want to run the MPARRM again
if ispc 
    EEGclean = MPARRM_SPES(EEG,...
                       'stimType',      'pulseOnset',          ...
                       'centerTime',    0,                     ...
                       'winTimeLen',    10,                    ...
                       'minMPepochLen', 50,                    ...
                       'savePath',      'MP',                  ...
                       'saveName',      'sample_SPES');
    save('sample data/artFree_sample_SPES.mat','EEG','EEGclean'); 
    disp('MPARRM DONE!')
end

%% show results
load('sample data/artFree_sample_SPES.mat','EEG','EEGclean'); 
figure('position',[10 10 800 400]);
subplot(1,3,1);hold on;
plot(EEG.times,squeeze(EEG.data(1,:,1)),'k','linewidth',3);
plot(EEG.times,squeeze(EEGclean.data(1,:,1)),'r','linewidth',1);
xlabel('Time (ms)'); ylabel('Amplitude (uV)');
xlim([-50 100]); set(gca,'fontsize',14)

% time-frequency
tf = {};
tf{1} = caltimef(EEG,     'channel',1,'plotersp','off','baseline',[-300 -100],'cycles',[3 0.8],'maxfreq',250);
tf{2} = caltimef(EEGclean,'channel',1,'plotersp','off','baseline',[-300 -100],'cycles',[3 0.8],'maxfreq',250);
subplot(1,3,2);
plottimef(tf{1},'channel',1,'clim',[-6 6],'xl',[-50 150],'showTitle',false,'showColorBar',false);
set(gca,'fontsize',14)
subplot(1,3,3);
plottimef(tf{2},'channel',1,'clim',[-6 6],'xl',[-50 150],'showTitle',false,'showColorBar',true,'colorBarXshift',0.06); 
set(gca,'fontsize',14)






