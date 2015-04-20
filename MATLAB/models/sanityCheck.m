clear all
% Model 1.16 is equivalent to MWR
load reduced.model.j.rnd.10x10.OPT.p.Local.1.16.mat
PREF=struct('Model',[],'nr_models',1);
PREF.Model{1}=reducedModel;    
%%
data=training;
Dimension=data.NrJobs*data.NrMacs;
SDR{data.NumInstances}=[];
PREF_IS_OPTIMAL=zeros(data.NumInstances,PREF.nr_models,Dimension);
for PID = 1:data.NumInstances,
    %% For each instance
    if isempty(data.opt_track(PID).dat)
        warning(sprintf('#%d missing',PID));
    else
        [~,SDR{PID},~,PREF_IS_OPTIMAL(PID,:,:)]=loopInstance(data.opt_track(PID),data.NrJobs,data.NrMacs,0,1,0,PREF);
    end
end
%%
PREF_IS_OPTIMAL=reshape(PREF_IS_OPTIMAL(:,1,:),data.NumInstances,Dimension);
MWR_IS_OPTIMAL=zeros(data.NumInstances,Dimension);
for PID=1:data.NumInstances
    MWR_IS_OPTIMAL(PID,1:Dimension)=SDR{PID}.MWR_IS_OPTIMAL;
end

close all, figure, hold on
plot(1:Dimension,mean(PREF_IS_OPTIMAL,1),'-b','LineWidth',4)
plot(1:Dimension,mean(MWR_IS_OPTIMAL,1),'-r','LineWidth',2)
legend(['PREF 1.16','MWR'],'location','best');
shg
