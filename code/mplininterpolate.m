function data = mplininterpolate(data,varargin)
% linear interpolate the stimualtion period to extract the low-frequency
% signal in the raw signal.
% data:   date for MP. Should be in the follow matrix: channelNum/trialLen/trialNum;
% Tao Xie, May/10/2022

%% define parameter
fieldlist = { 'centerLoc' 'integer' []   [];   % sampling point
              'winLen'    'integer' []   [];   % sampling point
              'rng'       'integer' []   [];   % sampling point
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
nbchan    = size(data,1);
nbpnt     = size(data,2);
nbtrial   = size(data,3);

%% main
if isempty(g.rng)
    centerLoc = round(g.centerLoc); 
    winLen    = round(g.winLen);  
    g.rng     = centerLoc-round(winLen/2):centerLoc+round(winLen/2);
end
for ch = 1:nbchan
for s = 1:nbtrial
    if 1<=g.rng(1) && g.rng(end)<=nbpnt
        d = data(ch,g.rng,s);
    end
    if g.rng(end)>nbpnt
        d = data(ch,[g.rng(1) g.rng(1)],s);
        g.rng = g.rng(1):nbpnt;
    end
    if g.rng(1)<1
        d = data(ch,[g.rng(end) g.rng(end)],s);
        g.rng = 1:g.rng(end);
    end
    data(ch,g.rng,s) = linspace(d(1),d(end),length(g.rng));
end
end

end