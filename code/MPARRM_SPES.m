function [EEGclean,mpDataSel,epLaten] = MPARRM_SPES(EEG,varargin)
% remove the stimulation artifact using MPARRM

% Tao Xie, May/18/2022
% please email xie@neurotechcenter.org if you have any further question


%% define parameter
% data:   date for MP. Should be in the follow matrix: channelNum/trialLen/trialNum;
fieldlist = { 'stimType'      'string'  []   'test';                       % onset of individule stimulation pulse  
              'iteration'     'integer' []   50;                           % iteration number for MP
              'centerTime'    'integer' []   0;                            % center time (ms) for MP atom selection
              'winTimeLen'    'integer' []   10;                           % window length length (ms) for MP atom selection
              'minMPepochLen' 'integer' []   50;                           % min epoch length (ms) for MP
              'savePath'      'string'  []   [cd '/MP'];                   % folder path to save the results
              'saveName'      'string'  []   'currentDataSet';
              'step1FreThre'  'integer' []   55;
              'step2FreThre'  'integer' []   170;
              'step3FreThre'  'integer' []   70;
              'loadEEGclean'  'integer' []   true;
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
eptLen   = 2^ceil(log2(g.minMPepochLen/1000*EEG.srate))/EEG.srate;
chLabel  = 'AllChannels';
EEGclean = [];

%% main
% define the epoch data for MP
EEGep   = pop_epoch(EEG,{g.stimType},[-eptLen/2 eptLen/2]);
epLaten = latencypnts_SPES(EEGep,EEG);
if mod(log2(EEGep.pnts),1)~=0; error('len should be power of 2'); end
mpCenterLoc = find(abs(EEGep.times)<1/EEGep.srate)+EEGep.srate*g.centerTime/1000;
if length(mpCenterLoc)~=1; error('!'); end
if EEGep.pnts>4096; error('!'); end

% =====================================================================
% Step 1: remove the period Noise 
% =====================================================================
% MP to extract the period noise
[mpDataSel, ~] = mpdenoising(EEGep.data,...
    'reCalMP',     false,...
    'srate',       EEGep.srate,...
    'mpCenterLoc', mpCenterLoc,...
    'mpWinLen',    EEGep.srate*g.winTimeLen/1000,...
    'mpIteration', g.iteration,...
    'mpFreThre',   g.step1FreThre, ...
    'mpRetrType',  'perioNoise',...
    'figShow',     false,...
    'mpName',chLabel,'mpPath',[g.savePath '/' g.saveName]);
if false
    for s = 1:5:60
        figure; hold on;
        plot(EEGep.times,EEGep.data(1,:,s),'k','linewidth',2); 
        plot(EEGep.times,mpDataSel(1,:,s),'r','linewidth',2)
        plot(EEGep.times,EEGep.data(1,:,s)-mpDataSel(1,:,s),'b','linewidth',2)
    end
end

% substract the period noise
EEGep.data = EEGep.data-mpDataSel;


% =====================================================================
% Step 2: remove the background signal
% =====================================================================
% interprete the stim period
eeg       = EEGep;
centerLoc = find(abs(eeg.times)<1/EEG.srate)+eeg.srate*g.centerTime/1000;
winLen    = eeg.srate*g.winTimeLen/1000;
eeg.data  = mplininterpolate(eeg.data,'centerLoc',centerLoc,'winLen',winLen/2);
if false % show the interprete results
    for i = 1:5:60
        figure; hold on;
        plot(eeg.times,squeeze(EEGep.data(1,:,i)),'color','k','linewidth',1)
        plot(eeg.times,squeeze(eeg.data(1,:,i)),'color','r','linewidth',1)
    end
end
[mpDataSel, ~] = mpdenoising(eeg.data,...
    'reCalMP',     false,...
    'srate',       eeg.srate,...
    'mpCenterLoc', mpCenterLoc,...
    'mpWinLen',    eeg.srate*g.winTimeLen/1000,...
    'mpIteration', g.iteration,...
    'mpFreThre',   g.step2FreThre, ...
    'mpRetrType',  'lFreTemplate',...
    'figShow',     false,...
    'mpName',chLabel,'mpPath',[g.savePath '/' g.saveName]);
if false
    for i = 1:5:60
        figure;hold on;  
        plot(EEGep.times,EEGep.data(1,:,i),'k'); 
        plot(eeg.times,mpDataSel(1,:,i),'r');
    end
end
% substract the background signal
EEGep.data = EEGep.data-mpDataSel;

% =====================================================================
% Step 3: extract the stimulation artifact
% =====================================================================
[mpDataSel, ~] = mpdenoising(EEGep.data,...
    'reCalMP',     false,...
    'srate',       EEGep.srate,...
    'mpCenterLoc', mpCenterLoc,...
    'mpWinLen',    EEGep.srate*g.winTimeLen/1000,...
    'mpIteration', g.iteration,...
    'mpFreThre',   g.step3FreThre, ...
    'mpRetrType',  'hFreNoise',...
    'figShow',     false,...
    'mpName',chLabel,'mpPath',[g.savePath '/' g.saveName]);
if false
    for i = 1:5:60
        figure;hold on;  
        plot(EEGep.times,EEGep.data(1,:,i),'k'); 
        plot(EEGep.times,mpDataSel(1,:,i),'r');
    end
end

%% remove the stimulation artifact
if g.loadEEGclean
    load([g.savePath '/' g.saveName '/' chLabel '_hFreNoise/retrive_' num2str(g.iteration) '.mat'],'mpDataSel');
    EEGclean  = mpremoveartifact_SPES(EEG,mpDataSel,epLaten);
end


