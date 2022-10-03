function data = mpremoveartifact_inraw(data,varargin)
% remove the stimulation artifact from the un-epoched data
% Tao Xie, Mar/29/2022

%% define parameter
fieldlist = { 'dataNoise'    'integer' []   [];         
              'latency'      'integer' []   [];  
              % for nanpoint
              'nanpoint'     'integer' []   false;  
              'mpCenterLoc', 'integer' []   [];  
              'mpWinLen',    'integer' []   [];  
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end

%% main
for s  = 1:size(g.dataNoise,3)
    d = squeeze(g.dataNoise(:,:,s));
    if g.nanpoint
        rng = round(g.mpCenterLoc)-round(g.mpWinLen)/2:round(g.mpCenterLoc)+round(g.mpWinLen)/2;
        data(:,g.latency(rng,s)) = 1;
        for ch = 1:size(d,1)
            data(ch,g.latency(abs(d(ch,:))>=1e-5,s)) = 1;
        end
    else
        data(:,g.latency(:,s)) = data(:,g.latency(:,s))-d;
    end 
end

end