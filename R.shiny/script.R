source('global.R')
save=NA
dim='10x10'
problem='j.rnd'
problems=c('j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc')
SDR=subset(dataset.SDR,Problem %in% problems & dim %in% dim)

source('sdr.R')
dataset.diff=checkDifficulty(subset(SDR, Set=='train' & dim==dim & Problem==problems))
print(xtable(dataset.diff$Quartiles), include.rownames = FALSE)
print(xtable(dataset.diff$Split), include.rownames = FALSE)
print(xtable(splitSDR(dataset.diff$Easy)))# first problem
print(xtable(splitSDR(dataset.diff$Easy)))# first problem
plot.SDR(SDR,'boxplot', save)
plot.BDR('10x10',problems,'SPT','MWR',40,save)

if(dim=='6x5'){
  source('gantt.R')
  gantt=get.gantt(problem,'6x5','MWR',10)
  plot.gantt(gantt,'30')
}

source('pref.trajectories.R')
tracks=c(sdrs,'ALL','OPT'); ranks=c('a','b','f','p')
trainingDataSize=get.trainingDataSize(problems,dim,tracks)
preferenceSetSize=get.preferenceSetSize(problems,dim,tracks,ranks)
rhoTracksRanks=get.rhoTracksRanks(problems,dim,tracks,ranks)
plot.trainingDataSize(trainingDataSize)
plot.preferenceSetSize(preferenceSetSize)
plot.rhoTracksRanks(rhoTracksRanks, SDR)
if(!is.null(rhoTracksRanks))
  print(xtable(table.rhoTracksRanks(problem, rhoTracksRanks, SDR),rownames=F))

source('opt.uniqueness.R'); smooth=F
all.StepwiseOptimality=get.StepwiseOptimality(problems,dim,'OPT')
plot.stepwiseUniqueness(all.StepwiseOptimality,smooth,save)
plot.stepwiseOptimality(all.StepwiseOptimality,F,smooth,save)

source('opt.SDR.R')
StepwiseOptimality=get.StepwiseOptimality(problem,dim,'OPT')
StepwiseExtremal=get.StepwiseExtremal(problem,dim)
plot.StepwiseSDR.wrtTrack(StepwiseOptimality,StepwiseExtremal,dim,F,save)

source('opt.bw.R')
plot.BestWorst(problems,dim,'OPT',save)
plot.BestWorst(problem,dim,'ALL',save)

if(dim=='10x10'){
  source('pref.exhaustive.R'); source('pref.settings.R')
  probability='equal'
  prefSummary=get.prefSummary(problems,'10x10','OPT','p',probability,F)
  paretoFront=get.paretoFront(prefSummary)
  bestPrefModel=get.bestPrefModel(paretoFront)

  plot.exhaust.paretoFront(prefSummary,paretoFront,T,save)
  plot.exhaust.acc(prefSummary,save)
  plot.exhaust.paretoWeights(paretoFront,F,save)
  plot.exhaust.bestAcc(all.StepwiseOptimality,bestPrefModel)
  plot.exhaust.bestBoxplot(bestPrefModel,SDR)
  print(table.exhaust.paretoFront(paretoFront),
        include.rownames=FALSE, sanitize.text.function=function(x){x})
  ks=suppressWarnings(get.pareto.ks(paretoFront,problem, onlyPareto = F, SDR=NULL))
  if(!is.null(ks)){
    print(ks$Rho.train,sanitize.text.function=function(x){x})
    print(ks$Rho.test,sanitize.text.function=function(x){x})
    print(ks$Acc,sanitize.text.function=function(x){x})
  }
}

source('feat.R')
plot.StepwiseExtremal(StepwiseOptimality,StepwiseExtremal,F)
plot.StepwiseFeatures(problem,dim,T,F)
plot.StepwiseFeatures(problem,dim,F,T)

source('pref.imitationLearning.R')
plot.imitationLearning.boxplot(problem,dim)
plot.imitationLearning.weights(problem,dim)
stats.imitationLearning(problem,dim)

if(dim=='6x5'){
  source('cma.R')
  evolutionCMA=get.evolutionCMA(problems,dim)
  plot.evolutionCMA.Weights(evolutionCMA,problem)
  plot.evolutionCMA.Fitness(evolutionCMA)
  plot.CMAPREF.timedependentWeights(problem, dim)
}
