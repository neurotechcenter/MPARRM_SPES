% Tao Xie May/29/2023

clc,clear;
addpath(genpath('code/MP_master'))    % Matching Pursuit method. For detail please see https://github.com/supratimray/MP
addpath('code/eeglab2022.0_simplify') % EEGLAB. For detail please see https://eeglab.org
addpath('code/MP_localcode')
eeglab; close all; clear;

%% load sample data
% the sample data is from two representative human SEEG electrodes with
% single-pulse electrical stimulation
EEG = pop_loadset('filepath','sample data','filename','sample_SPES.set');
     
%% remove the ERP component
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
xlim([-50 100]);xlabel('Time (ms)'); ylabel('Amplitude (uV)'); title('Raw Signal: ERP removed')
set(gca,'fontsize',14)

%% MPARRM
% the parameter related to MPARRM will be saved in "MP" folder
% please delate "MP" folder if you want to run the MPARRM again
% the current MP code can only be run on Mac OS
if false
    EEGclean = MPARRM_SPES(EEG);
    save('sample data/artFree_sample_SPES.mat','EEGclean'); 
    disp('MPARRM DONE!')
end

%% show results
load('sample data/artFree_sample_SPES.mat','EEGclean'); 
figure('position',[10 10 800 800]);
subplot(2,2,1);hold on;
plot(EEG.times,squeeze(EEG.data(1,:,:)));
plot([0 0],[-500 400],'--k');
xlim([-100 150]);ylim([-500 400]);xlabel('Time (ms)'); ylabel('Amplitude (uV)'); title('Raw SPES Signal')
set(gca,'fontsize',14)

subplot(2,2,2);hold on;
plot(EEGclean.times,squeeze(EEGclean.data(1,:,:)));
plot([0 0],[-500 400],'--k');
xlim([-100 150]);ylim([-500 400]);xlabel('Time (ms)'); ylabel('Amplitude (uV)'); title('Denoised Signal')
set(gca,'fontsize',14)

subplot(2,2,3);
par = caltimef(EEG);
plottimef(par,'clim',[-10 10],'showColorBar',false);
xlim([-100 150])
set(gca,'fontsize',14); title('Raw SPES Signal')

subplot(2,2,4);
par = caltimef(EEGclean);
plottimef(par,'clim',[-10 10],'colorBarXshift',0.06);
xlim([-100 150])
set(gca,'fontsize',14); title('Denoised Signal')
saveas(gca,'MPARRM result','png')













