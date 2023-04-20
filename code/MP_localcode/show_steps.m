function show_steps(eeg,mpDataSel,stepNum)

%%
if stepNum==1
    for s = 1:5:60
        figure; hold on;
        plot(EEGep.times,EEGep.data(1,:,s),'k','linewidth',2); 
        plot(EEGep.times,mpDataSel(1,:,s),'r','linewidth',2)
        plot(EEGep.times,EEGep.data(1,:,s)-mpDataSel(1,:,s),'b','linewidth',2)
    end
end