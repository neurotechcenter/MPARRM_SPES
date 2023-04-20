function EEG = linreplaceartifact(EEG, varargin)
% remove main stimulation artifact from each trial on each channel
% method extract from 10.1016/j.jneumeth.2018.09.034

% Tao Xie
% July/05/2022

%% define the parameter
fieldlist = {'stimMask'        'integer' []    [0 5];
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
EEGraw = EEG;

%% main
% start and end of each stim artifact
len   = ceil(diff(g.stimMask)/1000 * EEG.srate);
stimS = find(EEG.times==0) + ceil(g.stimMask(1)/1000*EEG.srate);
stimE = stimS + len;

% remove artifact
rampUp   = 0:1/len:1; % TODO: check this
rampDown = fliplr(rampUp);
for ch = 1:EEG.nbchan % each channel
for s  = 1:EEG.trials % each stimulus
    pre  = squeeze(EEG.data(ch,stimS-len:stimS,s))';
    post = squeeze(EEG.data(ch,stimE:stimE+len,s))';
    EEG.data(ch,stimS:stimE,s) = flipud(pre)' .* rampDown + flipud(post)' .* rampUp;
end
end

%% show the compare
if false
   ch = 5; s = 30;
   figure; hold on;
   plot(EEGraw.times,EEGraw.data(ch,:,s),'k','linewidth',2);
   plot(EEG.times,EEG.data(ch,:,s),'r','linewidth',1);
   plot(EEG.times(stimS),EEG.data(ch,stimS,s),'o','markerfacecolor','g','markersize',10)
   plot(EEG.times(stimE),EEG.data(ch,stimE,s),'o','markerfacecolor','g','markersize',10)
   xlim([-10 10])
   xlabel('Time (ms)'); ylabel('Amplitude'); set(gca,'fontsize',16)
end


end
