function eeg = mplininterpolate(eeg,varargin)
% linear interpolate the stimualtion period to extract the low-frequency
% signal in the raw signal.
% data:   date for MP. Should be in the follow matrix: channelNum/trialLen/trialNum;
% Tao Xie, May/10/2022

%% define parameter
fieldlist = { 'interpolateWin' 'integer' []   [];   % ms
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
eegRaw = eeg;

%% main
loc = find(g.interpolateWin(1)<=eeg.times&eeg.times<=g.interpolateWin(2));
for ch = 1:eeg.nbchan
for s  = 1:eeg.trials
    d1 = eeg.data(ch,loc(1),s);
    d2 = eeg.data(ch,loc(end),s);
    eeg.data(ch,loc,s) = linspace(d1,d2,length(loc));
end
end

%% show the figure
if false
    ch = 1; s = 11;
    figure;hold on;
    plot(eeg.times,eegRaw.data(ch,:,s),'k','linewidth',2);
    plot(eeg.times,eeg.data(ch,:,s),'r','linewidth',1);
    xlim([-20 20]); 
    xlabel('Time (ms)'); ylabel('Amplitude'); set(gca,'fontsize',16)
end


end