function xcf = caltimef(EEG,varargin)

% example:
% xcf = xcf_timef(EEG,'channel',1,'plotersp','on','baseline',nan,'cycles',[3 0.8],'maxfreq',170);
% xcf_plottimef(xcf,'channel',1); 

% Tao Xie
% May/31/2022

%% define parameter
fieldlist = { 'channel'       {'integer','cell'}    []  [];
              'plotersp'      'string'              []  'off';
              'plotitc'       'string'              []  'off';
              'maxfreq'       'integer'             []  170;
              'baseline'      'integer'             []  nan; % [-500 0] ms
              'cycles'        'integer'             []  [3 0.5];
            }; 
g = finputcheck(varargin, fieldlist);
if ischar(g), error(g); end

%% main
eeg = pop_select(EEG,'channel',g.channel);   
xcf = eeg;
xcf.g = g;
xcf = rmfield(xcf,{'data'});

% calculate the timef for individual channels
for ch = 1:eeg.nbchan
    [xcf.ersp(ch,:,:),xcf.itc(ch,:,:),xcf.powbase(ch,:),xcf.tims,xcf.fres,xcf.erspboot,xcf.itcboot] = ...
    newtimef(eeg.data(1,:,:),eeg.pnts, [eeg.xmin eeg.xmax]*1000, eeg.srate, g.cycles,...
    'padratio', 1,'maxfreq',g.maxfreq,'plotitc',g.plotitc,'plotersp',g.plotersp,'baseline',g.baseline);
end








