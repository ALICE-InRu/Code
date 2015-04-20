function [Main,SDR,Extremal,PREF_IS_OPTIMAL] = loopInstance(opt_track,NrJobs,NrMacs,checkMain,checkSDR,checkExtremal,PREF)
addpath ../common/
pattern=1;
if nargin<4, checkMain=true; end
if nargin<5, checkSDR=true; end
if nargin<6, checkExtremal=false; end

%%
global colMakespan colStep Dimension
global colSPT colMWR
Dimension=NrJobs*NrMacs;
[info,actualFeatures]=featureInfo();
colMakespan=find(strcmp('Makespan',info.header));
colStep=find(strcmp('phi.step',info.header));
colSPT=find(strcmp('phi.proc',info.header));
colMWR=find(strcmp('phi.wrmJob',info.header));
%%
if checkMain
    Main.RHOw=zeros(1,Dimension);
    Main.RHOb=zeros(1,Dimension);
    Main.RND_IS_OPTIMAL=zeros(1,Dimension);
    Main.OPT_IS_UNIQUE=zeros(1,Dimension);
    Main.MacOptAssignment=zeros(1,Dimension);
    Main.MacSameOptAssignment=zeros(1,Dimension);
else
    Main=[];
end

if checkExtremal
    Extremal.IS_OPTIMAL_MIN=zeros(info.nr_features,Dimension);
    Extremal.IS_OPTIMAL_MAX=zeros(info.nr_features,Dimension);
else
    Extremal=[];
end

if checkSDR
    SDR.MWR_IS_OPTIMAL=zeros(1,Dimension);
    SDR.SPT_IS_OPTIMAL=zeros(1,Dimension);
else
    SDR=[];
end

if exist('PREF','var')
    PREF_IS_OPTIMAL=zeros(PREF.nr_models,Dimension);
else
    PREF_IS_OPTIMAL=[];
end

%%
if (pattern == 1), xTime = opt_track.xTime; end
optimalMakespan = min(opt_track.dat(:,colMakespan));
%%
for step=1:Dimension
    %% filter data to this time step
    sdat = opt_track.dat((step==opt_track.dat(:,colStep)),:);
    optidx = find(sdat(:,colMakespan) == optimalMakespan);
    subidx = find(sdat(:,colMakespan) ~= optimalMakespan);
    cnt=size(sdat,1);
    %%
    if checkMain
        %% Check if random assignment is optimal
        Main.RND_IS_OPTIMAL(step) = length(optidx)/cnt;
        %% next best solution found is:
        [Main.RHOb(step),Main.RHOw(step)]=casescenario(optimalMakespan,sdat,subidx);
        %% check how many of the optimal dispatches will result in the same
        if (pattern == 1)
            if(step<Dimension)
                Main.OPT_IS_UNIQUE(step)=uniqueOptimal(optidx,xTime(:,(step==opt_track.dat(:,colStep))),cnt);
            else
                Main.OPT_IS_UNIQUE(step) = 1;
            end
        end
        %%
        %numSamples(IDNUM,step) = length(optidx)*length(subidx);
        %% the question here is in the case we have a suboptimal job assignment
        [Main.MacOptAssignment(step),Main.MacSameOptAssignment(step)] = optAssigment(sdat,optidx,subidx);
        %% What is the average work per job in this problem:
        % pmean = mean(problems(IDNUM).p(:));
        %% what is the average work remaining at this step
        % pwrm = mean(sdat(:,colMWR)); % per job
        %% what should it be at this stage, assuming random dispatching
        % pwrmave = pmean*(Dimension-step-1)/NrJobs;
        % WRMDIFF(IDNUM,step) = (pwrm - pwrmave)/((Dimension-step-1)/NrJobs);
        
        % pspt = mean(sdat(:,colSPT)); % what the processing time is
        % SPTDIFF(IDNUM,step) = pspt - pmean;
    end
    %% SDR are optimal?
    if checkSDR
        %% MWR is optimal?
        SDR.MWR_IS_OPTIMAL(step) = minmaxOptimal(sdat(:,colMWR),optidx,0);
        %% SPT is optimal?
        SDR.SPT_IS_OPTIMAL(step) = minmaxOptimal(sdat(:,colSPT),optidx,1);
    end
    %% Individual features are optimal?
    fdat=sdat(:,actualFeatures);    
    if checkExtremal        
        for feat=1:info.nr_features
            Extremal.IS_OPTIMAL_MIN(feat,step) = minmaxOptimal(fdat(:,feat),optidx,1);
            Extremal.IS_OPTIMAL_MAX(feat,step) = minmaxOptimal(fdat(:,feat),optidx,0);
        end
    end    
    %% Check if PREF model is optimal
    if exist('PREF','var')        
        for MID=1:PREF.nr_models
            fx= fdat * PREF.Model{MID}.w';
            modidx = find(fx == max(fx));
            if ~isempty(modidx)
                if any(modidx(1)==optidx)
                    PREF_IS_OPTIMAL(MID,step) = 1;
                end
            else
                PREF_IS_OPTIMAL(MID,step) = 1;
            end
        end
    end
    %%
end
end

function opt = minmaxOptimal(feature, optidx, minimise)
if nargin<3, minimise=1; end

if(minimise)
    fidx=find(feature == min(feature));
else
    fidx=find(feature == max(feature));
end

if ~isempty(fidx)
    isopt = intersect(optidx,fidx);
    if ~isempty(isopt) % any(fidx(1)==optidx)        
        %opt=1; 
        opt=length(isopt)/length(fidx);
    else
        opt=0;
    end
else
    opt=1;
end

end

function [macoptassignment macsameoptassignment] = optAssigment(sdat,optidx,subidx)
%% does there exist an optimal assignment on that same machine?
macoptassignment=0;
for j=1:length(subidx)
    % check if optimal assignment on same machine:
    if any(sdat(subidx(j),4) == sdat(optidx,4))
        macoptassignment = macoptassignment + 1;
    end
end
if ~isempty(subidx)
    macoptassignment = macoptassignment/length(subidx);
end
%% next question is how many optimal assignments are on the same machine?
macsameoptassignment=0;
for j=1:length(optidx)
    % check if optimal assignment on same machine:
    if (sum(sdat(optidx(j),4) == sdat(optidx,4))>1)
        macsameoptassignment = macsameoptassignment + 1;
    end
end
macsameoptassignment = macsameoptassignment/length(optidx);
end

function unique = uniqueOptimal(optidx,xT,cnt)
global Dimension
% optimal solution, first check how many unique optimal paths exsist?
xOptimal = zeros(Dimension,1);
ok = 0;
for j=1:length(optidx)
    found = 0;
    for k=1:size(xOptimal,2)
        if (sum(abs(xOptimal(1:Dimension,k)-xT(1:Dimension,optidx(j))))<0.001)
            found = 1;
        end
    end
    if (0 == found)
        ok = ok + 1;
        xOptimal(1:Dimension,ok) = xT(1:Dimension,optidx(j));
        % clf
        % ganttch(reshape(xOptimal(1:Dimension,ok),NrJobs,NrMacs),problems(IDNUM).p,problems(IDNUM).sigma,'text');
        % shg
    end
end
unique=size(xOptimal,2);%/cnt;
end

function [best,worst] = casescenario(optimalMakespan,sdat,subidx)

global colMakespan

suboptimalMakespan = max(sdat(subidx,colMakespan));
if isempty(suboptimalMakespan), suboptimalMakespan = optimalMakespan; end
worst = (suboptimalMakespan-optimalMakespan)/optimalMakespan;

suboptimalMakespan = min(sdat(subidx,colMakespan));
if isempty(suboptimalMakespan), suboptimalMakespan = optimalMakespan; end
best = (suboptimalMakespan-optimalMakespan)/optimalMakespan;

end