function [epLaten,epLatenNum] = latencypnts_inepoch(eeg,EEG,varargin)

% this function extract the latency pnts of eeg in epoched EEG
% Tao Xie Apr/21/2022

%% define parameter
fieldlist = { 'test'     'integer' []   [];  
              'test2'    'integer' []   [];  
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end

%% main
epLaten    = nan(eeg.pnts,eeg.trials);
epLatenNum = nan(1,eeg.trials);
thr        = 1/eeg.srate*1000*0.1;
for s = 1:eeg.trials
    % find the urevent num for each pulse in EEG
    if iscell(eeg.epoch(s).eventlatency)
        loc = find(cellfun(@(x)abs(x)<=thr,eeg.epoch(s).eventlatency)); 
        if isempty(loc); error('find the urevent num for each pulse in EEG !'); end
        urNum = eeg.epoch(s).eventurevent{loc(1)};
        % find the epoch num in EEG
        loc   = [EEG.event.urevent]==urNum; 
        epNum = EEG.event(loc).epoch;
        if isempty(epNum); error('find the epoch num in EEGraw !'); end
        % find the event num in each epoch of EEG
        sNum = find(cell2mat(EEG.epoch(epNum).eventurevent)==urNum);
        if length(sNum)~=1; error('find the event num in each epoch of EEGraw !'); end
        % define the latenRng
        [~,loc] = min(abs(EEG.times-EEG.epoch(epNum).eventlatency{sNum}));
        if length(loc)~=1; error('define the latenRng !'); end
    else
        epNum   = s;
        [~,loc] = min(abs(EEG.times-EEG.epoch(epNum).eventlatency));
    end
    
    % check the data
    continueCheck = true;
    for i = [loc loc-1 loc+1]
    if continueCheck
        latenRng = (1:eeg.pnts)-find(abs(eeg.times)<=thr)+i;
        if sum(eeg.data(1,:,s)-EEG.data(1,latenRng,epNum))==0;  continueCheck=false; end
    end
    end
    if continueCheck; error('check the data!'); end
    epLaten(:,s)  = latenRng;
    epLatenNum(s) = epNum;
end


end