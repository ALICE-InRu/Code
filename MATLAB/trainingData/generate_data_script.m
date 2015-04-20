function generate_data_script(distr,dim,track,print)
if(nargin<4) print=0; end 
if(nargin<3) track='IL1SUP'; end
if(nargin<2) dim='6x5'; end
if(nargin<1) distr='j.rnd'; end
Ntrain=500;
%%
addpath ../common/
addpath ../opt/
problems  = getproblem(sprintf('../../rawData/%s.%s.train.txt',distr,dim));
fname=sprintf('%s.%s.train.%s.hi.mat',distr,dim,track);
pname=sprintf('%s.%s.train.%s.tpr.mat',distr,dim,track);
OPT=load(sprintf('../opt/opt.%s.%s.train.mat',distr,dim));
%% Get weights for features w.r.t. trajectory to follow
wLCDR=getWeight(distr,dim,previousTrack(track));
%%
if exist(fname)
    load(fname);
    start=length(DAT)+1;
else
    start=1;
end
%%
if exist(pname)
    tryRetrace=1;
    prev=load(pname);
else
    tryRetrace=0;
end
%%
for PID = start:Ntrain, 
    disp(sprintf('generate_data: problem %s.%s.%d (of %d) following %s track', distr, dim, PID, Ntrain,track))
    %%
    if(tryRetrace & PID <= length(prev.DAT))
        if(~isempty(prev.DAT(PID).dat))
            [DAT(PID).dat, DAT(PID).xTime, DAT(PID).model, DAT(PID).result] = retrace_generate_data(problems(PID).p,problems(PID).sigma,prev.DAT(PID),OPT.DAT(PID));
            if isempty(DAT(PID).dat)
                fromScratch=1;
            else
                fromScratch=0;
            end
        else
            fromScratch=1;
        end
    else
        fromScratch=1;
    end    
    %%
    if(fromScratch)
        [DAT(PID).dat, DAT(PID).xTime, DAT(PID).model, DAT(PID).result] = generate_data(problems(PID).p,problems(PID).sigma,track,print,wLCDR);
    end
    save(fname,'DAT')
end

%cd trainingData/
%mat2csv(distr,dim,track);
