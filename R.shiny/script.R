source('global.R')
save=NA
input=list(dimension='10x10',problem='j.rnd',problems=c('j.rnd','j.rndn','f.rnd'))
#input=list(dimension='6x5',problem='j.rnd',problems=c('j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc'))
SDR=subset(dataset.SDR,Problem %in% input$problems & Dimension %in% input$dimension)
input$bias='equal'
input$timedependent=F

source('sdr.R')
dataset.diff=checkDifficulty(subset(SDR, Set=='train' & Dimension==input$dimension & Problem%in%input$problems))
print(xtable(dataset.diff$Quartiles), include.rownames = FALSE)
print(xtable(dataset.diff$Split), include.rownames = FALSE)
print(xtable(splitSDR(dataset.diff$Easy)))# first problem
print(xtable(splitSDR(dataset.diff$Easy)))# first problem
plot.SDR(SDR,'boxplot', save)
plot.BDR(input$dimension,input$problems,'SPT','MWR',40,save)

source('gantt.R')
gantt=get.gantt(input$problem,input$dimension,'MWR',10)
plot.gantt(gantt,'30')

source('pref.trajectories.R')
tracks=c(sdrs,'ALL','OPT'); ranks=c('a','b','f','p')
trainingDataSize=get.trainingDataSize(input$problems,input$dimension,tracks)
preferenceSetSize=get.preferenceSetSize(input$problems,input$dimension,tracks,ranks)
CDR.full=get.many.CDR(get.CDR.file_list(input$problems,input$dimension,tracks,ranks,input$timedependent,input$bias),'train')
plot.trainingDataSize(trainingDataSize)
plot.preferenceSetSize(preferenceSetSize)
plot.rhoTracksRanks(CDR.full, SDR)
if(!is.null(CDR.full))
  print(xtable(table.rhoTracksRanks(input$problem, CDR.full, SDR),rownames=F))

source('opt.uniqueness.R'); smooth=F
all.StepwiseOptimality=get.StepwiseOptimality(input$problems,input$dimension,'OPT')
plot.stepwiseUniqueness(all.StepwiseOptimality,smooth,save)
plot.stepwiseOptimality(all.StepwiseOptimality,F,smooth,save)

source('opt.SDR.R')
StepwiseOptimality=get.StepwiseOptimality(input$problem,input$dimension,'OPT')
StepwiseExtremal=get.StepwiseExtremal(input$problem,input$dimension)
plot.StepwiseSDR.wrtTrack(StepwiseOptimality,StepwiseExtremal,input$dimension,F,save)

source('opt.bw.R')
plot.BestWorst(input$problems,input$dimension,'OPT',save)
plot.BestWorst(input$problem,input$dimension,'ALL',save)

source('pref.exhaustive.R'); source('pref.settings.R')
prefSummary=get.prefSummary(input$problems,input$dimension,'OPT','p',F,input$bias)
paretoFront=get.paretoFront(prefSummary)
bestPrefModel=get.bestPrefModel(paretoFront)

plot.exhaust.paretoFront(prefSummary,paretoFront,T,save)
plot.exhaust.acc(prefSummary,save)
plot.exhaust.paretoWeights(paretoFront,F,save)
plot.exhaust.bestAcc(all.StepwiseOptimality,bestPrefModel)
plot.exhaust.bestBoxplot(bestPrefModel,SDR)
print(table.exhaust.paretoFront(paretoFront),
      include.rownames=FALSE, sanitize.text.function=function(x){x})
ks=suppressWarnings(get.pareto.ks(paretoFront,input$problem, onlyPareto = F, SDR=NULL))
if(!is.null(ks)){
  print(ks$Rho.train,sanitize.text.function=function(x){x})
  print(ks$Rho.test,sanitize.text.function=function(x){x})
  print(ks$Acc,sanitize.text.function=function(x){x})
}

source('feat.R')
plot.StepwiseExtremal(StepwiseOptimality,StepwiseExtremal,F)
plot.StepwiseFeatures(input$problem,input$dimension,T,F)
plot.StepwiseFeatures(input$problem,input$dimension,F,T)

source('pref.imitationLearning.R')
CDR.IL <- get.CDR.IL(input$problem,input$dimension)
plot.imitationLearning.boxplot(CDR.IL)
stats.imitationLearning(CDR.IL)
plot.imitationLearning.weights(input$problem,input$dimension)

if(input$dimension=='6x5'){
  source('cma.R')
  evolutionCMA=get.evolutionCMA(input$problems,input$dimension)
  plot.evolutionCMA.Weights(evolutionCMA,input$problem)
  plot.evolutionCMA.Fitness(evolutionCMA)
  plot.CMAPREF.timedependentWeights(input$problem, input$dimension)
}
