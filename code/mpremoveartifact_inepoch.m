function data = mpremoveartifact_inepoch(data,varargin)
% remove the stimulation artifact from the epoched data
% Tao Xie, May/14/2022

%% define parameter
fieldlist = { 'dataNoise'    'integer' []   [];         
              'epLaten'      'integer' []   [];  
              'epLatenNum'   'integer' []   [];  
              };   
g = finputcheck( varargin, fieldlist);
if ischar(g), error(g); end
nbchan  = size(data,1);
nbtrial = size(g.dataNoise,3);

%% main
for s  = 1:nbtrial
    d = squeeze(g.dataNoise(:,:,s));
    data(:,g.epLaten(:,s),g.epLatenNum(s)) = squeeze(data(:,g.epLaten(:,s),g.epLatenNum(s)))-d;
end


end