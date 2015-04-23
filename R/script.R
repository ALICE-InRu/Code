source('startUp.R')
dpi=300
extension='pdf' # because if smooth is true eps doesn't work
subdir='../../Papers/Thesis/figures/'
redoPlot=F

# ----- Problem structure -----------------------------------------
source('difficultywrtFeatures.R')
for(problem in problems.6x5){  difficulty.wrt.features(problem,'6x5',diff$Quartiles, 'ALL') }
for(problem in problems.10x10){  difficulty.wrt.features(problem,'10x10',diff$Quartiles, 'OPT') }

# ------------------------------------------------------------------
if(extension=='png'){
  source('proctimes.R'); 
  proctimes('6x5',diff$Quartiles,SDR)
  proctimes('10x10',diff$Quartiles,SDR)
}
# ------------------------------------------------------------------
if(file.exists('trdat.Rdata')){ load('trdat.Rdata')} else {
  TRDAT.6x5=getfilesTraining('6x5',Global=T)
  TRDAT.10x10=getfilesTraining('10x10',Global=T)
  save(list=c('TRDAT.6x5','TRDAT.10x10','diff'),file='trdat.Rdata')
}

source('difficultywrtFeatures.R');
if(extension=='png'){ difficulty.wrt.features(TRDAT.6x5,diff$Quartiles) }
#features.evolution(TRDAT.6x5)
if(extension=='png'){ difficulty.wrt.features(TRDAT.10x10,diff$Quartiles) }
#features.evolution(TRDAT.10x10)

# ------------------------------------------------------------------
source('inspectSimplexIterations.R')
inspectSimplexIterations(rbind(TRDAT.6x5,TRDAT.10x10))
# ------------------------------------------------------------------
source('optimalityOfDispatches.R')
inspectOptimumTrajectory('*.OPT.Global.csv')
inspectOptimalityFromMatlab()

# ---- LIBLINEAR -----------
dimension <- '10x10'
trajectory='OPT'
rank <- 'p'
Ntrain <- 300
source('liblinear.R')
subdir=paste(liblinearDir,'figures',sep='/');
problem='j.rnd'
timedependent=F
info.all=plotLiblinearModels(problem, dimension, rank, timedependent, c('equal','opt','bcs','wcs'), T)
info.equal=plotLiblinearModels(problem, dimension, rank, timedependent, 'equal', T)
info.bcs=plotLiblinearModels(problem, dimension, rank, timedependent, 'bcs', F)
info.wcs=plotLiblinearModels(problem, dimension, rank, timedependent, 'wcs', F)
info.opt=plotLiblinearModels(problem, dimension, rank, timedependent, 'opt', F)

#sanity check
#subset(info.equal$Weights,NrFeat==1 & Model==1) # phi.proc: +1 = LPT and -1 = SPT
#subset(info.equal$Weights,NrFeat==1 & Model==16) # phi.wrmJob: +1 = MWR and -1 = LWR

#print('Stats over all 697 models')
#ddply(info.all$Liblinear.Summary, ~Problem, function(X) data.frame(Training.Acc.Stepwise = as.list(summary(X$Training.Acc.Stepwise)),Model.Cnt=nrow(X)))
#ddply(info.all$Liblinear.Summary, ~Problem, function(X) data.frame(Training.Rho = as.list(summary(X$Training.Rho)),Model.Cnt=nrow(X)))
#print('Stats over pareto front')
#ddply(subset(info.all$Pareto.front,Pareto.front==T), ~Problem, function(X) data.frame(Training.Acc.Stepwise = as.list(summary(X$Training.Acc.Stepwise)),Model.Cnt=nrow(X)))
#ddply(subset(info.all$Pareto.front,Pareto.front==T), ~Problem, function(X) data.frame(Training.Rho = as.list(summary(X$Training.Rho)),Model.Cnt=nrow(X)))

liblinearXtable(info.equal)
liblinearXtable(info.all)

#best.equal=liblinearComparedToOptimal(info.equal); print(best.equal)
#best.all=liblinearComparedToOptimal(info.all); print(best.all)

#liblinearBoxplot(best.equal,info.equal$Probability)
#liblinearBoxplot(best.all,info.all$Probability)

liblinearKolmogorov(info)
