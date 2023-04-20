function EEGclean = mpremoveartifact_SPES(EEG,mpDataSel,epLaten)
% remove the stimulation artifact from the epoched data
% Tao Xie, May/14/2022

%% main
EEGclean = EEG;
for s = 1:EEG.trials
    d = squeeze(mpDataSel(:,:,s));
    EEGclean.data(:,epLaten(:,s),s) = squeeze(EEG.data(:,epLaten(:,s),s))-d;
end

if false
    for indxCh = 1:5:20
    for s = 1:20:60
        figure;hold on;
        plot(EEG.times,EEG.data(indxCh,:,s),'k');
        plot(EEGclean.times,EEGclean.data(indxCh,:,s),'r');
        xlim([250 350])
    end
    end
end


end