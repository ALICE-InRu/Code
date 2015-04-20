source('startUp.R')
dpi=300
extension='pdf' # because if smooth is true eps doesn't work
subdir='../../Papers/Thesis/figures/'
redoPlot=F

# ----- Problem structure -----------------------------------------
source('difficultywrtSDR.R'); 
#boxplotSDRs(SDR,c('6x5','10x10')) # # Figure A.1

diff=checkDifficulty(subset(SDR,Set=='train' & Dimension %in% c('6x5','10x10')))
#splitSDR(subset(diff$Easy)) # \label{tbl:hard:cnt:6x5,tbl:hard:cnt:10x10}
#splitSDR(subset(diff$Hard)) # \label{tbl:easy:cnt:6x5,tbl:easy:cnt:10x10}

source('difficultywrtFeatures.R')
for(problem in problems.6x5){  difficulty.wrt.features(problem,'6x5',diff$Quartiles, 'ALL') }
for(problem in problems.10x10){  difficulty.wrt.features(problem,'10x10',diff$Quartiles, 'OPT') }

source('optimalityOfDispatches.R'); 
plotStepwiseUnique(problems.6x5,'6x5') # Figure A.2a
plotStepwiseUnique(problems.10x10,'10x10') # Figure A.2b

plotStepwiseOptimality(problems.6x5,'6x5') # Figure A.3a
plotStepwiseOptimality(problems.10x10,'10x10') # Figure A.3b

plotStepwiseBestWorst('6x5',onlyOPT = T) # Figura A.4a
plotStepwiseBestWorst('10x10',onlyOPT = T) # Figura A.4b
plotStepwiseBestWorst('6x5',onlyOPT = F) # Figure A.8

plotStepwiseSDR.wrtOPT(problems.6x5,'6x5') # Figure A.5a
plotStepwiseSDR.wrtOPT(problems.10x10,'10x10') # Figure A.5b
plotStepwiseSDR.wrtTrack(problems.6x5,'6x5')

for(problem in problems.6x5){ 
  plotStepwiseExtremal(problem,'6x5',T); # Figure A.6
  plotStepwiseFeatures(problem,'6x5'); # Figure A.7
}
for(problem in problems.10x10){ 
  plotStepwiseExtremal(problem,'10x10',T); # Figure A.6
  plotStepwiseFeatures(problem,'10x10') # Figure A.7
}

source('inspectBDR.R')
p=checkBDR(OPT,subset(SDR, Dimension=='10x10'),'SPT','MWR',40)
p = p + ggplotFill('Dispatching rule',3,c('SPT (first 40%), MWR (last 60%)','Shortest Processing Time','Most Work Remaining'))
fname=paste(subdir,'boxplotRho.BDR.10x10','.',extension,sep='')
ggsave(fname,width=Width,height=Height.half,dpi=dpi,units=units) # Figure 4.1

#inspectOptimumTrajectory('*.OPT.Global.csv')
#inspectOptimalityFromMatlab(SMOOTH = T,dim = '10x10',rank = 'p', SavePlots = T)
#inspectOptimalityFromMatlab(SMOOTH = T,dim = '6x5',rank = 'p', SavePlots = T)

# ----- LIBLINEAR --------------------------------------------------
source('liblinear.R')
for(problem in problems.6x5){
  for(track in c('OPT','SPT','LPT','MWR','LWR','ALL','RND')){
    for(rank in c('p','b','f','a')){
      createLiblinearModel(problem,'6x5',track,rank,probabilities = 'equal', lmax.timedependent=5000,lmax.timeindependent=100000, onlyFullModel = T)        
    }
  }
  estimateLiblinearModels(problem,'6x5','full')  
}

for(problem in problems.10x10){    
  createLiblinearModel(problem,'10x10','OPT',rank = 'p',times = 'timeindependent',lmax.timeindependent=500000)        
  estimateLiblinearModels(problem,'10x10','exhaust')  
}

# ----- IMITATION LEARNING -----------------------------------------
source('liblinear.R')
problem='j.rnd';dim='10x10';rank='p'
for(track in c('IL1SUP','IL1UNSUP',
               'IL2SUP','IL2UNSUP',
               'IL3SUP','IL3UNSUP',
               'IL4SUP','IL4UNSUP',
               'IL5SUP','IL5UNSUP',
               'IL6SUP','IL6UNSUP',
               'IL7SUP','IL7UNSUP')){
  createLiblinearModel(problem,dim,track,rank,probabilities = 'equal', lmax.timedependent=5000,lmax.timeindependent=100000, onlyFullModel = T, times = 'timeindependent')  
}
estimateLiblinearModels(problem,dim,'full')
stat=checkImitationLearning(problem,dim,rank)
# clearly the best PREF model yet! 
# need to compare it to CMA-ES

# ------------------------------------------------------------------

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

# Create linear models, and log weights in sub directory
createLiblinearModels(probabilities = 'equal', scales = F)
# Before next step, apply csharp code for getting the rho estimates
# Retrieve stats on rho estimates
estimateLiblinearModels()

info.all=plotLiblinearModels(scales = F, plotSeparately = T)
info.equal=plotLiblinearModels(scales = F, probabilities = 'equal', plotSeparately = T)
info.bcs=plotLiblinearModels(scales = F, probabilities = 'bcs')
info.wcs=plotLiblinearModels(scales = F, probabilities = 'wcs')
info.opt=plotLiblinearModels(scales = F, probabilities = 'opt')

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

best.equal=liblinearComparedToOptimal(info.equal); print(best.equal)
best.all=liblinearComparedToOptimal(info.all); print(best.all)

liblinearBoxplot(best.equal,info.equal$Probability)
liblinearBoxplot(best.all,info.all$Probability)

liblinearKolmogorov(info)
