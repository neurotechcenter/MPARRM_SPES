function epLaten = latencypnts_SPES(eeg,EEG,varargin)

% this function extract the latency pnts of eeg in epoched EEG
% Tao Xie Apr/21/2022

%% define parameter
fieldlist = { 'test'     'string' []   '';  
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end

%% main
epLaten = nan(eeg.pnts,eeg.trials);
for s = 1:eeg.trials
    d   = eeg.data(1,:,s);
    dat = EEG.data(1,:,s);
    for i = 1:length(dat)-length(d)
        rng = i:i+length(d)-1;
        if sum(dat(rng)-d)==0
            epLaten(:,s) = rng;
            break;
        end
    end
end


end