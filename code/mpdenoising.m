function mpDataSel = mpdenoising(data,varargin)
% this function is used to denoising the stimulus artifact by using
% matching pursuit (MP). The MP toolbox is downloaded from https://github.com/supratimray/MP.
% For more information about the MP, please read the Chandran et al., 2016,
% doi: 10.1523/JNEUROSCI.3633-15.2016

% Tao Xie, May/12/2022
% please email xie@neurotechcenter.org if you have any further question

% mpDataSel: return reconstracted signal with selected atoms
% mpDataRsd: reture reconstracted signal with residual atoms

%% define parameter
% data:   date for MP. Should be in the follow matrix: channelNum/trialLen/trialNum;
fieldlist = { 'srate'        'integer' []   [];           % sampling rate
              'mpIteration'  'integer' []   50;           % iteration number for MP
              'mpCenterLoc'  'integer' []   1;            % center point for MP atom selection
              'mpWinLen'     'integer' []   10;           % window length length (point) for MP atom selection
              'mpFreThre'    'integer' []   70;           % frequency threthold
              'mpRetrType'   'string' []    '';           % retrive type: hFreNoise, perioNoise, lFreTemplate
              'mpName'       'string' []    'MPtest';     % name of the dataset
              'mpPath'       'string'  []   cd;           % folder path to save the results
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
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
newfolder(g.mpPath);
mpNameType = [g.mpName '_' g.mpRetrType];

% extract the data infor
nbchan    = size(data,1);
nbpnt     = size(data,2);
nbtrial   = size(data,3);
mpDataSel = nan(size(data));
if mod(log2(nbpnt),1)~=0; error('len should be power of 2'); end

%% Matching Pursuit
% remove the previous MP results if reCalMP is true
if exist([g.mpPath '/' mpNameType], 'dir')==7 && g.reCalMP
    status = rmdir([g.mpPath '/' mpNameType],'s'); pause(2);
    if status~=1; error('!'); end
end

% only perform the MP when the MP folder is not exist
if  exist(platformSpecificNameMPP([g.mpPath '/' mpNameType '/GaborMP/mp0.bok.000']),'file')==0
    disp('Running MP decomposition...');
    mp       = [];
    mp.L     = nbpnt;
    mp.fs    = g.srate;
    mp.name  = mpNameType;
    dataMP   = nan(mp.L,nbtrial*nbchan);
    for ch = 1:nbchan
        dataMP(:,nbtrial*(ch-1)+1:nbtrial*ch) = double(squeeze(data(ch,:,:)));
    end
    
    % Perform Gabor decomposition
    importData(dataMP,[g.mpPath '/'],[mpNameType '/'],[1 mp.L],mp.fs);       % import Data
    runGabor([g.mpPath '/'],[mpNameType '/'],mp.L,g.mpIteration);            % Perform Gabor decomposition
    
    % retrieve information
    gbtmp = getGaborData([g.mpPath '/'], mpNameType, 1); % Retrieve information
    for ch = 1:nbchan
        mp.gb(ch,:) = gbtmp(nbtrial*(ch-1)+1:nbtrial*ch);
    end
    save([g.mpPath '/' mpNameType '/mp.mat'],'mp');
    disp('calMP done!');
else
    disp('MP decomposition data already exists. Skipping MP decomposition...');
end

%% retrive the data
calRetrive = true;
if exist([g.mpPath '/' mpNameType '/retrive.mat'],'file')==2
    load([g.mpPath '/' mpNameType '/retrive.mat'],'mpDataSel','gRetr');
    if g.srate == gRetr.srate && g.mpCenterLoc == gRetr.mpCenterLoc && ...
       g.mpWinLen == gRetr.mpWinLen && g.mpFreThre == gRetr.mpFreThre
       calRetrive = false;
    end
end
    
% retrive the signal
if calRetrive
    disp('calRetrive...');
    load([g.mpPath '/' mpNameType '/mp.mat'],'mp');
    if mp.fs~=g.srate; error('the srate should be equal!'); end
    if mp.L~=nbpnt || size(mp.gb,2)~=nbtrial || size(mp.gb,1)~=nbchan; error('the length should be equal!'); end
    for ch = 1:nbchan
    for s  = 1:nbtrial
        gbData = mp.gb{ch,s}.gaborData;
        oct    = gbData(1,:);               % atom octave
        ksi    = gbData(2,:).*(mp.fs/mp.L); % atom frequency (between 0 and N/2)
        u      = gbData(3,:);               % atom center time (between 0 and N-1)
        maxOct = nextpow2(mp.L);
        s2     = 2.^(oct+1);
        w      = zeros(1,size(gbData,2));   % Gaussian width
        for a = 1:size(gbData,2) 
            if 0<oct(a) && oct(a)<maxOct-1
                w(1,a) = ((u(a)+s2(a))-(u(a)-s2(a)))/mp.L; 
            end
        end
        % conditions
        c1 = oct==0;                 % Dirac atom
        c2 = oct==maxOct;            % Fourier atom
        c3 = oct==maxOct-1;          % large Gaussian width atom
        c4 = 0<oct & oct<maxOct-1 & s2<=u & u<=mp.L-1-s2;   % Gabor style
        c5 = g.mpCenterLoc-g.mpWinLen/2<=u & u<=g.mpCenterLoc+g.mpWinLen/2;  % center time rng

        % define the select atoms
        switch g.mpRetrType
            case 'hFreNoise'
                c0 =  c4 & c5 & (ksi>=g.mpFreThre | ksi==0);
                atomSelect = (c1&c5) | c0; 
            case 'perioNoise'
                %atomSelect = (c2|c3|w>=0.5) & ksi>=g.mpFreThre;
                atomSelect = (c2|c3) & ksi>=g.mpFreThre;
            case 'lFreTemplate'
                %atomSelect = c4 & ksi<=g.mpFreThre;
                atomSelect = c1 | c2 | c3 | ksi<=g.mpFreThre;
        end

        % retrive the data
        datSel  = zeros(1,mp.L);
        if sum(atomSelect)>0;  datSel = reconstructSignalFromAtomsMPP(gbData,mp.L,1,find(atomSelect)); end
        mpDataSel(ch,:,s) = single(datSel);

        % show the MP results
        mpdenoising_showfig;
    end
    end

    % save the retrive signal
    gRetr = g; save([g.mpPath '/' mpNameType '/retrive.mat'],'mpDataSel','gRetr');
end




end