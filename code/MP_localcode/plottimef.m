function h = plottimef(par,varargin)

% Tao Xie
% Oct/06/2022

%% define parameter
fieldlist = { 'chanNum'          'integer'          []  1;
              'clim'             'integer'          []  [-5 5];
              'showColorBar'     'integer'          []  true;
              'fontSize'         'integer'          []  10;
              'colorBarXshift'   'integer'          []  0.05;
            }; 
g = finputcheck(varargin, fieldlist);
if ischar(g), error(g); end
if length(g.chanNum)~=1; error('Only allow to plot one channel!'); end

%% main
% show the 2D image
h = imagesc(par.tims,par.fres,squeeze(par.ersp(g.chanNum,:,:)), g.clim); hold on;
set(gca,'ydir','normal');
colormap(brewermap(128,'*RdBu'));
plot([0 0],par.fres([1 end]),'--k');

% show the colorbar
if g.showColorBar
    c = colorbar('location','eastoutside','AxisLocation','out');
    c.Position(1) = c.Position(1) + g.colorBarXshift;
    if isnan(par.g.baseline(1))
        c.Label.String = 'ERSP (10*log10(\muV^2/Hz))';
    else
        c.Label.String = 'ERSP (dB)';
    end
end

% set label info
xlabel('Time (ms)'); 
ylabel('Frequency (Hz)'); 

end



