function EEG = MPARRM_SPES(EEG,varargin)
% remove the stimulation artifact using MPARRM
% Tao Xie, Apr/16/2023
% please email xie@neurotechcenter.org if you have any further question


%% define parameter
fieldlist = { 'mpWin'          'integer' []   [-5 5];                       % window (ms) for MP atom selection
              'interpolateWin' 'integer' []   [-5 5];                       % window (ms) for linear interpolate
              'iteration'      'integer' []   50;                           % iteration number for MP
              'minMPepochLen'  'integer' []   50;                           % min epoch length (ms) for MP
              'savePath'       'string'  []   [cd '/MP'];                   % folder path to save the results
              'removeGabFile'  'integer' []   true;
              'step1FreThre'   'integer' []   55;
              'step2FreThre'   'integer' []   170;
              'step3FreThre'   'integer' []   70;
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
eptLen = 2^ceil(log2(g.minMPepochLen/1000*EEG.srate))/EEG.srate;
EEGep  = pop_select(EEG,'time',[-eptLen/2 eptLen/2]);
if mod(log2(EEGep.pnts),1)~=0; error('len should be power of 2'); end
if EEGep.pnts>4096; error('!'); end

%% main
if exist([g.savePath '/retrive_hFreNoise_' num2str(g.iteration) '.mat'],'file')~=2
    % Step 1: remove the period Noise 
    mpDataSel = mpdenoising(EEGep,g,'mpFreThre',g.step1FreThre,'mpRetrType','perioNoise');
    if false; show_steps(EEGep,mpDataSel,1); end
    EEGep.data = EEGep.data-mpDataSel; 

    % Step 2: remove the background signal
    eeg = mplininterpolate(EEGep,'interpolateWin',g.interpolateWin);
    mpDataSel = mpdenoising(eeg,g,'mpFreThre',g.step2FreThre,'mpRetrType','lFreTemplate');
    if false; show_steps(EEGep,mpDataSel,2); end
    EEGep.data = EEGep.data-mpDataSel;

    % Step 3: extract the stimulation artifact
    mpDataSel = mpdenoising(EEGep,g,'mpFreThre',g.step3FreThre,'mpRetrType','hFreNoise');
    if false; show_steps(EEGep,mpDataSel,3); end
end

%% remove the stimulation artifact
load([g.savePath '/retrive_hFreNoise_' num2str(g.iteration) '.mat'],'mpDataSel');
[~,ia] = intersect(EEG.times,EEGep.times);
if unique(EEG.times(ia)-EEGep.times)~=0; error('!'); end
EEG.data(:,ia,:) = EEG.data(:,ia,:)-mpDataSel;

end


