function par = caltimef(EEG,varargin)

% example:
% xcf = xcf_timef(EEG,'channel',1,'plotersp','on','baseline',nan,'cycles',[3 0.8],'maxfreq',170);
% xcf_plottimef(xcf,'channel',1); 

% Tao Xie
% Oct/06/2022

%% define parameter
fieldlist = { 'channel'       {'integer','cell'}    []  1;
              'plotersp'      'string'              []  'off';
              'plotitc'       'string'              []  'off';
              'maxfreq'       'integer'             []  170;
              'baseline'      'integer'             []  [-400 -100]; % [-500 0] ms
              'cycles'        'integer'             []  [3 0.5];
            }; 
g = finputcheck(varargin, fieldlist);
if ischar(g), error(g); end

%% main
if ~isempty(g.channel)
    EEG = pop_select(EEG,'channel',g.channel);  
end
par   = EEG; 
par   = rmfield(par,{'data'});
par.g = g;

% calculate the timef for each channel using 'newtimef' function
for ch = 1:EEG.nbchan
    [par.ersp(ch,:,:),par.itc(ch,:,:),par.powbase(ch,:),par.tims,par.fres,par.erspboot,par.itcboot] = ...
    newtimef(EEG.data(ch,:,:),EEG.pnts, [EEG.xmin EEG.xmax]*1000, EEG.srate, g.cycles,...
    'padratio', 1,'maxfreq',g.maxfreq,'plotitc',g.plotitc,'plotersp',g.plotersp,'baseline',g.baseline);
end








