% function: mpdenoising_showfig

% the function is part of the mpdenoising function.
% show the matching pursuit results for individual trials

% Tao Xie, Mar/22/2022

% show the MP results
'figShow'         'integer' []   false;
'figPath'         'string'  []   cd;
'figChanNums'     'integer' []   1;
'figChanLabs'     'cell'    []   {};
'figTrialNums'    'integer' []   1;
'figVisible'      'string'  []   'on';
'figFormat'       'string'  []   'png';

%% main
% g.figVisible = 'on';
if g.figShow && ismember(s, g.figTrialNums) && ismember(ch, g.figChanNums)
    if isempty(g.figChanLabs); chanLab = ['ch' num2str(ch)]; else; chanLab=g.figChanLabs{g.figChanNums==ch}; end
    figNam = [g.mpName '_' g.mpRetrType '_' chanLab '_trial' num2str(s)];

    % show all the atom individually
    figure('position',[10 10 1200 700],'visible',g.figVisible,'color',[1 1 1]); set(gcf,'renderer','Painters')
    [ha, pos] = tight_subplot(5, 10, [0.05 0.02], [0.05 0.1], [0.05 0.01],true);
    num = size(gbData,2);num(num>=50) = 50;
    k   = 1;
    t   = (1:mp.L)/mp.fs*1000;
    for atom = 1:num
        subplot(ha(k)); hold on;
        retData = reconstructSignalFromAtomsMPP(gbData,mp.L,1,atom);
        col = 'b'; if atomSelect(atom); col='r'; end
        yl  = [min(retData) max(retData)]; if diff(yl)==0; yl = [yl(1)-1 yl(1)+1]; end
        plot(t,retData,'color',col,'linewidth',2)
        % show the center rng
        plot([1 1]*(g.mpCenterLoc-g.mpWinLen/2)/mp.fs*1000,yl,'--k');
        plot([1 1]*(g.mpCenterLoc+g.mpWinLen/2)/mp.fs*1000,yl,'--k');
        text(0.5,1.1,['f' num2str(round(ksi(atom))) ';o'  num2str(oct(atom)) ';w' num2str(w(atom))],'units','normalize','horizontalalign','center','fontsize',12,'color',col)
        if k==41; xlabel('Time (s)'); ylabel('Amp (uV)'); end
        if k~=41; set(gca,'xtick',[]), end
        xlim(t([1 end])); ylim(yl); set(gca,'fontsize',12);
        k = k+1;
    end
    axes('position',[0 0.95 1 0.05]);axis off;
    text(0.5,0.5,figNam,'units','normalized','horizontalalign','center','fontsize',20,'interpreter','none')
    saveas(gcf,[g.figPath '/' figNam '_atoms'],g.figFormat); if strcmp(g.figVisible,'off'); close(gcf); end

    % show all the atom together
    figure('position',[10 10 800 500],'visible',g.figVisible,'color',[1 1 1]); set(gcf,'renderer','Painters')
    [ha, pos] = tight_subplot(1, 2, [0.05 0.1], [0.1 0.1], [0.1 0.2],false);
    num = size(gbData,2);num(num>=50) = 50;
    subplot(ha(1)); hold on; axis on;
    for atom = 1:num
        retData = reconstructSignalFromAtomsMPP(gbData,mp.L,1,atom);
        col = 'b'; if atomSelect(atom); col='r'; end
        plot(t,retData-(atom-1)*5,'color',col,'linewidth',1)
    end
    xlabel('Time (ms)'); ylabel('Amplitude (uV)'); axis tight; grid on; set(gca,'fontsize',18)
    title(figNam,'fontsize',20,'interpreter','none')

    subplot(ha(2)); hold on; axis on;
    datSel = mpDataSel(ch,:,s);
    hs(1) = plot(t,data(ch,:,s),'k','linewidth',1); % before remove noise
    hs(2) = plot(t,datSel,'r','linewidth',1);
    hs(3) = plot(t,data(ch,:,s)-datSel,'g','linewidth',1.5); % after remove noise
    retData = reconstructSignalFromAtomsMPP(gbData,mp.L,1,1:size(gbData,2));
    hs(4) = plot(t,retData,'color',[.5 .5 .5],'linewidth',1);
    xlim(t([1 end])); 
    yl = [min(datSel) max(datSel)];
    plot([1 1]*(g.mpCenterLoc-g.mpWinLen/2)/mp.fs*1000,yl,'--k');
    plot([1 1]*(g.mpCenterLoc+g.mpWinLen/2)/mp.fs*1000,yl,'--k');
    legend(hs,{'Raw trace','Stim Noise','Clean trace','All retrive'},'position',[0.85 0.8 0.1 0.1]); xlabel('Time (ms)'); ylabel('Amplitude (uV)');
    set(gca,'fontsize',18)
    saveas(gcf,[g.figPath '/' figNam],g.figFormat); if strcmp(g.figVisible,'off'); close(gcf); end
end