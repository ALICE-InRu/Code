function [mean_acc,stepwise_acc] = stepwiseTrainingAccuracy(data,PREF,model,showPlot)
if nargin<4, showPlot=false; end
%%
if isempty(PREF)
    dispPID=false;    
    if isempty(model), error('Missing PREF model'); end
    PREF=struct('Model',[],'nr_models',1);
    PREF.Model{1}=model;
else
    dispPID=true;    
    disp(sprintf('%s contains %d models',PREF.weightFile,PREF.nr_models));
end

%%
PREF_IS_OPTIMAL=zeros(data.NumInstances,PREF.nr_models,data.NrJobs*data.NrMacs);
for PID = 1:data.NumInstances, 
    %% For each instance
    if isempty(data.opt_track(PID).dat)
        warning(sprintf('#%d missing',PID));
    else
        if dispPID, disp(PID); end
        [~,~,~,PREF_IS_OPTIMAL(PID,:,:)]=loopInstance(data.opt_track(PID),data.NrJobs,data.NrMacs,0,0,0,PREF);
    end
end
%%
Dimension=data.NrJobs*data.NrMacs;
stepwise_acc=zeros(Dimension,PREF.nr_models);
for MID=1:PREF.nr_models
    stepwise_acc(1:Dimension,MID)=mean(reshape(PREF_IS_OPTIMAL(:,MID,:),data.NumInstances,Dimension),1);
end
mean_acc=mean(stepwise_acc);

if(showPlot) figure, plot(stepwise_acc); title(data.Name); shg; end

end