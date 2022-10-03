function h = plottimef(par,varargin)

% example:
% xcf_plottimef(xcf,'xl',[],'showColorBar',true,'showXlabel',false,'showYlabel',false,'showTitle',false,'colorBarXshift',0.1)

% Tao Xie
% June/14/2022

%% define parameter
fieldlist = { 'channel'          'integer'          []  [];
              'clim'             'integer'          []  [-5 5];
              'color'            'string'           []  '*RdBu'; % check brewermap
              'xl'               'integer'          []  [];
              'showColorBar'     'integer'          []  true;
              'fontSize'         'integer'          []  10;
              'interpreter'      'string'           []  'none';
              'showXlabel'       'integer'          []  true;
              'showYlabel'       'integer'          []  true;
              'showXTickLabel'   'integer'          []  true;
              'showYTickLabel'   'integer'          []  true;
              'showTitle'        'integer'          []  true;
              'colorBarXshift'   'integer'          []  true;
              'colorBarLocation' 'string'           []  'eastoutside';
            }; 
g = finputcheck(varargin, fieldlist);
if ischar(g), error(g); end
if length(g.channel)~=1; error('!'); end

%% main
h = imagesc(par.tims,par.fres,squeeze(par.ersp(g.channel,:,:)), g.clim); hold on;
set(gca,'ydir','normal');
colormap(brewermap(128,g.color));
plot([0 0],par.fres([1 end]),'--k');
if ~isempty(g.xl); xlim(g.xl); end
if g.showColorBar
    c = colorbar('location',g.colorBarLocation,'AxisLocation','out');
    c.Position(1) = c.Position(1) + g.colorBarXshift;
    if isnan(par.g.baseline(1))
        c.Label.String = 'ERSP (10*log10(\muV^2/Hz))';
    else
        c.Label.String = 'ERSP (dB)';
    end
end
if g.showXlabel; xlabel('Time (ms)'); end
if g.showYlabel; ylabel('Frequency (Hz)'); end
if g.showTitle;  title(par.chanlocs(g.channel).labels,'interpreter',g.interpreter); end



end



