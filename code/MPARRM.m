function [EEGclean,EEGart] = MPARRM(EEG,varargin)
% remove the stimulation artifact using MPARRM

% Tao Xie, May/18/2022
% please email xie@neurotechcenter.org if you have any further question

%% define parameter
fieldlist = { 'stimType'      'string'  []   'test';                      
              'iteration'     'integer' []   50;                           % iteration number for MP
              'centerTime'    'integer' []   0;                            % center time (ms) for MP atom selection
              'winTimeLen'    'integer' []   10;                           % window length length (ms) for MP atom selection
              'minMPepochLen' 'integer' []   50;                           % min epoch length (ms) for MP
              'savePath'      'string'  []   [cd '/MP'];                   % folder path to save the results
              'saveName'      'string'  []   'currentDataSet';
              'runIndivChan'  'integer' []   false;                        % set 'true' with create a new folder for each channel
              'step1FreThre'  'integer' []   55;
              'step2FreThre'  'integer' []   170;
              'step3FreThre'  'integer' []   70;
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
eptLen  = 2^ceil(log2(g.minMPepochLen/1000*EEG.srate))/EEG.srate;
runNum  = 1; if g.runIndivChan; runNum = EEG.nbchan; end
chLabel = 'AllChannels';

%% main
for indxCh = 1:runNum
    if g.runIndivChan
        EEGs    = pop_select(EEG,'channel',indxCh); % single channel
        chLabel = EEG.chanlocs(indxCh).labels;
    else
        EEGs    = EEG;
    end
    
    % define the epoch data for MP
    EEGep = pop_epoch(EEGs,{g.stimType},[-eptLen/2 eptLen/2]);
    if mod(log2(EEGep.pnts),1)~=0; error('len should be power of 2'); end
    mpCenterLoc = find(abs(EEGep.times)<1/EEGep.srate)+EEGep.srate*g.centerTime/1000;
    if length(mpCenterLoc)~=1; error('!'); end
    if EEGep.pnts>4096; error('!'); end

    % =====================================================================
    % Step 1: remove the period Noise 
    % =====================================================================
    % MP to extract the period noise
    eeg  = EEGep;
    mpDataSel = mpdenoising(eeg.data,              ...
        'reCalMP',     false,                      ...
        'srate',       eeg.srate,                  ...
        'mpCenterLoc', mpCenterLoc,                ...
        'mpWinLen',    eeg.srate*g.winTimeLen/1000,...
        'mpIteration', g.iteration,                ...
        'mpFreThre',   g.step1FreThre,             ...
        'mpRetrType',  'perioNoise',               ...
        'figShow',     false,                      ...
        'mpName',chLabel,'mpPath',[g.savePath '/' g.saveName]);
        
    % substract the period noise
    EEGep.data = EEGep.data-mpDataSel;

    % interprete the non-taget stim
    if max(cellfun(@(x)length(x),{EEGep.epoch.event}))>1
        eeg = EEGep; 
        for s = 1:EEGep.trials
            loc = cellfun(@(x)contains(x,g.stimType),(EEGep.epoch(s).eventtype));
            loc = cell2mat((EEGep.epoch(s).eventlatency(loc)));
            loc(loc==0) = [];
            for i = 1:length(loc)
                [~,c]     = min(abs(EEGep.times-loc(i))); if length(c)~=1; error('!'); end
                centerLoc = c+EEGep.srate*g.centerTime/1000;
                winLen    = EEGep.srate*g.winTimeLen/1000;
                EEGep.data(:,:,s)  = mplininterpolate(EEGep.data(:,:,s),'centerLoc',centerLoc,'winLen',winLen);
            end
        end
    end
    
    % =====================================================================
    % Step 2: remove the background signal
    % =====================================================================
    % interprete the stim period
    eeg       = EEGep;
    centerLoc = find(abs(eeg.times)<1/EEG.srate)+eeg.srate*g.centerTime/1000;
    winLen    = eeg.srate*g.winTimeLen/1000;
    eeg.data  = mplininterpolate(eeg.data,'centerLoc',centerLoc,'winLen',winLen);
    
    % MP to extract the background signal
    mpDataSel = mpdenoising(eeg.data,               ...
        'reCalMP',     false,                       ...
        'srate',       eeg.srate,                   ...
        'mpCenterLoc', mpCenterLoc,                 ...
        'mpWinLen',    eeg.srate*g.winTimeLen/1000, ...
        'mpIteration', g.iteration,                 ...
        'mpFreThre',   g.step2FreThre,              ...
        'mpRetrType',  'lFreTemplate',              ...
        'figShow',     false,                       ...
        'mpName',chLabel,'mpPath',[g.savePath '/' g.saveName]);

    % substract the background signal
    EEGep.data = EEGep.data-mpDataSel;

    % =====================================================================
    % Step 3: extract the stimulation artifact
    % =====================================================================
    eeg      = EEGep;
    mpDataSel = mpdenoising(eeg.data,               ...
        'reCalMP',     false,                       ...
        'srate',       eeg.srate,                   ...
        'mpCenterLoc', mpCenterLoc,                 ...
        'mpWinLen',    eeg.srate*g.winTimeLen/1000, ...
        'mpIteration', g.iteration,                 ...
        'mpFreThre',   g.step3FreThre,              ...
        'mpRetrType',  'hFreNoise',                 ...
        'figShow',     false,                        ...
        'mpName',chLabel,'mpPath',[g.savePath '/' g.saveName]);
end
    
%% remove the stimulation artifact
EEGep = pop_epoch(EEG,{g.stimType},[-eptLen/2 eptLen/2]);
if isempty(EEG.epoch)
    [epLaten,epLatenNum] = latencypnts_inraw(EEGep,EEG);
else
    [epLaten,epLatenNum] = latencypnts_inepoch(EEGep,EEG);
end
EEGclean = EEG;
EEGart   = EEGep;
if g.runIndivChan
    for indxCh = 1:EEG.nbchan
        chLabel = EEG.chanlocs(indxCh).labels;
        load([g.savePath '/' g.saveName '/' chLabel '_hFreNoise/retrive.mat'],'mpDataSel');
        EEGclean.data(indxCh,:,:) = mpremoveartifact_inepoch(EEG.data(indxCh,:,:),'dataNoise',mpDataSel,'epLaten',epLaten,'epLatenNum',epLatenNum);
        EEGart.data(indxCh,:,:)   = single(mpDataSel);
    end
else
    load([g.savePath '/' g.saveName '/' chLabel '_hFreNoise/retrive.mat'],'mpDataSel');
    EEGclean.data = mpremoveartifact_inepoch(EEG.data,'dataNoise',mpDataSel,'epLaten',epLaten,'epLatenNum',epLatenNum);
    EEGart.data   = single(mpDataSel);
end
EEGart.nbchans  = EEG.nbchan;
EEGart.chanlocs = EEG.chanlocs;
EEGart = eeg_checkset(EEGart);


