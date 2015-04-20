clear all; 
Bias=-3.909913e-15;
distr='f.rnd'; dim='10x10'; 

header={'phi.mac','phi.startTime','phi.arrivalTime','phi.wrmJob','phi.proc','phi.jobOps','phi.wrmTotal','phi.wait','phi.slotReduced','phi.macFree','phi.makespan','phi.wrmMac','phi.slots','phi.endTime'};
model_all = struct('Parameters',0,'nr_class',2,'nr_feature',14,'bias',Bias,'Label',[1 -1], 'w',zeros(1,14)); 

model_all.w(find(strcmp(header, 'phi.arrivalTime')))=0.2493305;
model_all.w(find(strcmp(header, 'phi.macFree')))=-0.01550758;
model_all.w

save(sprintf('model.%s.%s.mat',distr,dim)); 