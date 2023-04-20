function mpDataSel = mpdenoising(eeg,par,varargin)
% this function is used to denoising the stimulus artifact by using
% matching pursuit (MP). Before run this function, you should first download the
% EEGLAB from https://eeglab.org and the MP toolbox from https://github.com/supratimray/MP.
% For more information about the MP, please read the Chandran et al., 2016,
% doi: 10.1523/JNEUROSCI.3633-15.2016

% Tao Xie, May/12/2022
% please email xie@neurotechcenter.org if you have any further question

% mpDataSel: return reconstracted signal with selected atoms
% mpDataRsd: reture reconstracted signal with residual atoms

%% define parameter
fieldlist = { 'mpFreThre'    'integer' []   [];           % frequency threthold
              'mpRetrType'   'string' []    '';           % retrive type: hFreNoise, perioNoise, lFreTemplate
              'reCalMP'      'integer' []   false;        % re-calculate the MP
              % show the MP results
              'figShow'         'integer' []   false;
              'figPath'         'string'  []   cd;
              'figChanNums'     'integer' []   1;
              'figChanLabs'     'cell'    []   {};
              'figTrialNums'    'integer' []   1;
              'figVisible'      'string'  []   'on';
              'figFormat'       'string'  []   'png';
              };   
g = finputcheck(varargin, fieldlist);
if ischar(g), error(g); end
newfolder(par.savePath);
mpDataSel = nan(size(eeg.data));  % selected signal
if mod(log2(eeg.pnts),1)~=0; error('len should be power of 2'); end


%% Matching Pursuit
if exist([par.savePath '/mp_' g.mpRetrType '.mat'],'file')~=2
    disp('Running MP decomposition...');
    mp       = [];
    mp.L     = eeg.pnts;
    mp.fs    = eeg.srate;
    mp.name  = g.mpRetrType;
    dataMP   = nan(mp.L,eeg.trials*eeg.nbchan);
    for ch = 1:eeg.nbchan
        dataMP(:,eeg.trials*(ch-1)+1:eeg.trials*ch) = double(squeeze(eeg.data(ch,:,:)));
    end
    
    % Perform Gabor decomposition
    importData(dataMP,[par.savePath '/'],[g.mpRetrType '/'],[1 mp.L],mp.fs);       % import Data
    runGabor([par.savePath '/'],[g.mpRetrType '/'],mp.L,par.iteration);            % Perform Gabor decomposition
    
    % retrieve information
    disp('retrieve...');
    gbtmp = getGaborData([par.savePath '/'], g.mpRetrType, 1); % Retrieve information
    for ch = 1:eeg.nbchan
        mp.gb(ch,:) = gbtmp(eeg.trials*(ch-1)+1:eeg.trials*ch);
    end
    save([par.savePath '/mp_' g.mpRetrType '.mat'],'mp');
    
    % remove Gabor files
    if par.removeGabFile
        rmdir([par.savePath '/' g.mpRetrType],'s'); pause(0.1);
    end
    
    disp('calMP done!');
else
    disp('MP decomposition data already exists. Skipping MP decomposition...');
end

%% extract selected atoms
if exist([par.savePath '/retrive_' g.mpRetrType '_' num2str(par.iteration) '.mat'],'file')~=2
    disp('Extract selected atoms...');
    load([par.savePath '/mp_' g.mpRetrType '.mat'],'mp');
    if mp.fs~=eeg.srate; error('the srate should be equal!'); end
    if mp.L~=eeg.pnts || size(mp.gb,2)~=eeg.trials || size(mp.gb,1)~=eeg.nbchan; error('the length should be equal!'); end

    for ch = 1:eeg.nbchan
    for s  = 1:eeg.trials
        gbData = mp.gb{ch,s}.gaborData;
        oct    = gbData(1,:);               % atom octave
        ksi    = gbData(2,:).*(mp.fs/mp.L); % atom frequency; gbData(2,:) is between 0 and N/2
        u      = gbData(3,:);               % atom center time (between 0 and N-1)
        maxOct = nextpow2(mp.L);
        s2     = 2.^(oct+1);
        w      = zeros(1,size(gbData,2));   % Gaussian width
        for a = 1:size(gbData,2) 
            if 0<oct(a) && oct(a)<maxOct-1
                w(1,a) = ((u(a)+s2(a))-(u(a)-s2(a)))/mp.L; 
            end
        end
        t1 = find(par.mpWin(1)<=eeg.times,1);
        t2 = find(par.mpWin(2)<=eeg.times,1);
        % conditions
        c1 = oct==0;                                        % Dirac atom
        c2 = oct==maxOct;                                   % Fourier atom
        c3 = oct==maxOct-1;                                 % large Gaussian width atom
        c4 = 0<oct & oct<maxOct-1 & s2<=u & u<=mp.L-1-s2;   % Gabor style
        c5 = t1<=u & u<=t2;                                 % center time rng

        % define the select atoms
        switch g.mpRetrType
            case 'perioNoise'
                %atomSelect = (c2|c3|w>=0.5) & ksi>=g.mpFreThre;
                atomSelect = (c2|c3) & ksi>=g.mpFreThre;
            case 'lFreTemplate'
                atomSelect = c1 | c2 | c3 | ksi<=g.mpFreThre;
                %atomSelect = c4 & ksi<=g.mpFreThre;
            case 'hFreNoise'
                c0 =  c4 & c5 & (ksi>=g.mpFreThre | ksi==0); % both sharp Gabor and sharp Gaussian 
                atomSelect = (c1&c5) | c0;                   % sharp Gabor, sharp Gaussian and Dirac around stimulation onset
        end

        % retrive the data
        datSel     = zeros(1,mp.L);
        atomSelect = atomSelect(1:par.iteration);
        if sum(atomSelect)>0;  datSel = reconstructSignalFromAtomsMPP(gbData,mp.L,1,find(atomSelect)); end
        mpDataSel(ch,:,s) = single(datSel);

        % show the individual MP atoms
        mpdenoising_showfig;
    end
    end

    % save the retrive signal
    save([par.savePath '/retrive_' g.mpRetrType '_' num2str(par.iteration) '.mat'],'mpDataSel');
    disp('Extract selected atoms: Done!');
else
    load([par.savePath '/retrive_' g.mpRetrType '_' num2str(par.iteration) '.mat'],'mpDataSel');
end


%datRsd  = zeros(1,mp.L);
%if sum(~atomSelect)>0; datRsd = reconstructSignalFromAtomsMPP(gbData,mp.L,1,find(~atomSelect)); end
%mpDataRsd(ch,:,s) = single(datRsd);