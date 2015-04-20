function [info,actualFeatures] = featureInfo()

info.header={'phi.step','Makespan','job',...
    'phi.mac','phi.startTime','phi.arrivalTime','phi.wrmJob','phi.proc',...
    'phi.jobOps','phi.wrmTotal','phi.wait','phi.slotReduced','phi.macfree',...
    'phi.makespan','phi.wrmMac','phi.slots','phi.endTime',...
    'auka.2','auka.3','auka.4'};
actualFeatures=find(strncmp('phi.',info.header,4));
info.features=info.header(actualFeatures);
info.nr_features=length(actualFeatures);

end
