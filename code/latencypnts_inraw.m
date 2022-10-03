function [epLaten, epLatenNum] = latencypnts_inraw(eegep,EEG)

% this function extract the latency pnts of eeg in raw EEG (i.e., un-epoched EEG)
% Tao Xie Apr/21/2022

%% main
% remove the boundary of EEG
loc = cellfun(@(x)strcmp(x,'boundary'),{EEG.event.type});
EEG.event(loc) = []; 

epLaten    = nan(eegep.pnts,eegep.trials);
epLatenNum = ones(1,eegep.trials);
thr     = 1/eegep.srate*0.1;
for s = 1:eegep.trials
    % find the urevent num for each pulse in EEG
    if iscell(eegep.epoch(s).eventlatency)
        loc = find(cellfun(@(x)abs(x)<=thr,eegep.epoch(s).eventlatency)); 
        if isempty(loc); error('find the urevent num for each pulse in EEG !'); end
        urNum = eegep.epoch(s).eventurevent{loc(1)};
    else
        if eegep.epoch(s).eventlatency~=0; error('!'); end
        urNum = eegep.epoch(s).eventurevent;
    end

    % find the epoch num in EEG
    loc  = [EEG.event.urevent]==urNum; 
    latenRng = (1:eegep.pnts)-find(abs(eegep.times)<=thr)+floor(EEG.event(loc).latency);

    % check the data
    if sum(eegep.data(1,:,s)-EEG.data(1,latenRng))~=0
        error('check the data!'); 
    end
    epLaten(:,s) = latenRng;
end



end