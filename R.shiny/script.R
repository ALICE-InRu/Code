source('global.R')
colorPalette='Greys';
extension='pdf';subdir='../../Thesis/figures/'
save=NA
input=list(dimension='10x10',problem='j.rnd',problems=c('j.rnd','j.rndn','f.rnd'))
#input=list(dimension='6x5',problem='j.rnd',problems=c('j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc','j.rnd_pj1doubled','j.rnd_p1mdoubled'))
SDR=subset(dataset.SDR,Problem %in% input$problems & Dimension %in% input$dimension)
input$timedependent=F
input$smooth=F
input$testProblems='ORLIB'

source('sdr.R')
dat<-subset(SDR, Set=='train' & Dimension==input$dimension & Problem%in%input$problems)
quartiles <- get.quartiles(dat)
dataset.diff=checkDifficulty(dat,quartiles)

print(xtable(dataset.diff$Quartiles), include.rownames = FALSE)
print(xtable(dataset.diff$Split), include.rownames = FALSE)
print(xtable(splitSDR(dataset.diff$Easy)))# first problem
print(xtable(splitSDR(dataset.diff$Easy)))# first problem
plot.SDR(SDR,'boxplot', save)
BDR <- get.BDR('10x10','j.rnd','SPT','MWR',c(10,15,20,30,40),F)
plot.BDR('10x10','j.rnd','SPT','MWR',c(10,15,20,30,40),NA,F,BDR = BDR)
ddply(BDR,~Problem+Dimension+BDR+SDR+Set,function(x) summary(x$Rho))



source('pref.trajectories.R'); source('cmaes.R')
input$dimension='6x5'
tracks=c(sdrs,'ALL','OPT','CMAESMINRHO','CMAESMINCMAX'); ranks=c('a','b','f','p')
trainingDataSize=get.trainingDataSize(input$problems,input$dimension,tracks)
preferenceSetSize=get.preferenceSetSize(input$problems,input$dimension,tracks,ranks)
CDR.full <- get.many.CDR(get.CDR.file_list(input$problems,input$dimension,tracks,ranks,input$timedependent),'train')
CDR.compare <- get.CDRTracksRanksComparison(input$problems,input$dimension,tracks)
plot.trainingDataSize(trainingDataSize)
plot.preferenceSetSize(preferenceSetSize)
plot.rhoTracksRanks(CDR.full, CDR.compare)
if(!is.null(CDR.full))
  print(xtable(table.rhoTracksRanks(input$problem, CDR.full, SDR),rownames=F))

ks <- compare.Baseline(tracks,subset(CDR.full,Rank=='p'),CDR.compare)

ks=ks.CDR(CDR.full,'Rank',c('Problem','Dimension','Track'))
any(ks[,grep('H:',colnames(ks))]==T); ks

for(problem in input$problems){
  CDR.full <- get.many.CDR(get.CDR.file_list(problem,input$dimension,tracks,'p',F),'train')
  mu <- ddply(CDR.full,~Problem+Dimension+Track,summarise,Rho=mean(Rho))
  print(arrange(mu,Problem,Dimension,Rho)$Track)
  ks=ks.CDR(CDR.full,'Track',c('Problem','Dimension','Track'))
  ks=melt(ks,c('Problem','Dimension'))
  print(arrange(ks[ks$value==F,],Problem))
}

source('opt.uniqueness.R');
all.StepwiseOptimality=get.StepwiseOptimality(input$problems,input$dimension,'OPT')
plot.stepwiseUniqueness(all.StepwiseOptimality,input$dimension,input$smooth,save)
plot.stepwiseOptimality(all.StepwiseOptimality,input$dimension,F,input$smooth,save)

source('opt.SDR.R')
StepwiseOptimality=get.StepwiseOptimality(input$problems,input$dimension,'OPT')
StepwiseExtremal=get.StepwiseExtremal(input$problems,input$dimension)
p=plot.StepwiseSDR.wrtTrack(StepwiseOptimality,StepwiseExtremal,input$dimension,F,NA,onlyWrtSDR = T)
zoom=p+theme(legend.position="none")+xlab(NULL)+scale_linetype_manual('',values=c(2))+
  scale_x_continuous(expand = c(0,0), limits=c(0,30))+
  facet_grid(~Problem, labeller= function(variable,value){ return('Zoom') })

source('opt.bw.R')
plot.BestWorst(input$problems,input$dimension,'OPT',save)
plot.BestWorst(input$problem,input$dimension,'ALL',save)

lapply(input$problems, function(problem){
  print(bw.spread(problem,'10x10',orderTrack=T))
})

source('pref.exhaustive.R'); source('pref.settings.R')
prefSummary=get.prefSummary(input$problems,input$dimension,'OPT','p',F)
paretoFront=get.paretoFront(prefSummary)
bestPrefModel=get.bestPrefModel(paretoFront)

plot.exhaust.paretoFront(prefSummary,paretoFront,T,save)
plot.exhaust.acc(prefSummary,save,bestPrefModel$Summary)
#plot.exhaust.paretoWeights(subset(prefSummary,NrFeat==1 & Problem==input$problem),rhoTxt = T)
for(problem in input$problems){
  print(plot.exhaust.paretoWeights(subset(paretoFront,Problem==problem),'save',F))
}

plot.exhaust.bestAcc(all.StepwiseOptimality,bestPrefModel)
plot.exhaust.bestBoxplot(bestPrefModel,SDR)
print(table.exhaust.paretoFront(paretoFront),
      include.rownames=FALSE, sanitize.text.function=function(x){x})
ks=suppressWarnings(get.pareto.ks(paretoFront,input$problem, onlyPareto = F, SDR=NULL))
if(!is.null(ks)){
  plot.ks.test2(ks$Rho.train,ks$Acc)
  plot.ks.test2(ks$Rho.test)
}

source('feat.R')
CDR.singleFeat <- get.SingleFeat.CDR(input$problem, input$dimension)
stats.singleFeat(CDR.singleFeat)
plot.StepwiseExtremal(StepwiseOptimality,StepwiseExtremal,CDR.singleFeat,input$dimension,F)
plot.StepwiseEvolution(input$problem,input$dimension)

source('feat.footprints.R')
trdat <- get.files.TRDAT(input$problem, input$dimension, 'ALL', useDiff = F)
trdat <- subset(trdat,Followed==T)
trdat <- label.trdat(trdat,quartiles)
trdat <- subset(trdat,Difficulty %in% c('Easy','Hard'))

corr.rho.sdr <- do.call(rbind, lapply(sdrs[1:4], function(sdr) {
  df <- correlation.matrix.stepwise(subset(trdat,Track==sdr),'FinalRho',F)
  df$Track = sdr
  return(df) } ))

p.sdr=plot.correlation.matrix.stepwise(corr.rho.sdr)+theme(legend.position='none')+xlab(NULL)
if(!is.na(save)){
  fname = paste(paste(subdir,input$problem,'phi',sep='/'),'corr','SDR',input$dimension,extension,sep = '.')
  ggsave(fname,p.sdr,width = Width, height = Height.half, dpi = dpi, units = units)
}

corr.rho.all <- correlation.matrix.stepwise(trdat,'FinalRho')
corr.rho.all$Track='ALL'
p.all=plot.correlation.matrix.stepwise(corr.rho.all)
if(!is.na(save)){
  fname = paste(paste(subdir,input$problem,'phi',sep='/'),'corr','ALL',input$dimension,extension,sep = '.')
  ggsave(fname,p.all,width = Width, height = Height.half, dpi = dpi, units = units)
}

mdat=ddply(rbind(corr.rho.sdr,corr.rho.all),~Track,summarise,
           N.Easy=sum(Significant & Difficulty=='Easy'),
           N.Hard=sum(Significant & Difficulty=='Hard'))
print(xtable(mdat), include.rownames = FALSE)
print(colSums(mdat[,2:3]))

ks.rho <- do.call(rbind, lapply(sdrs[1:4], function(sdr) {
  df <- ks.matrix.stepwise(subset(trdat,Track==sdr),T)
  df$Track = sdr
  return(df) } ))
p=plot.ks.matrix.stepwise(ks.rho)
if(!is.na(save)){
  fname = paste(paste(subdir,input$problem,'phi',sep='/'),'ks','SDR',input$dimension,extension,sep = '.')
  ggsave(fname,p,width = Width*1.2, height = Height.half*1.2, dpi = dpi, units = units)
}
mdat=ddply(ks.rho,~Track+N.Easy+N.Hard,summarise,Significant=sum(Significant))
print(xtable(mdat), include.rownames = FALSE)
print(colSums(mdat[,2:4]))

source('pref.imitationLearning.R')
CDR.IL <- get.CDR.IL(input$problem,input$dimension)
plot.imitationLearning.boxplot(CDR.IL)
stats.imitationLearning(CDR.IL)
plot.imitationLearning.weights(input$problem,input$dimension)

if(input$dimension=='6x5'){
  source('cmaes.R')
  evolutionCMA = do.call(rbind, lapply(c('6x5','10x10'), function(dim) {
    get.evolutionCMA(input$problems,dim)}))

  plot.evolutionCMA.Weights(subset(evolutionCMA,Timedependent==T &
                                     Dimension==input$dimension),input$problem)
  p.fit <- plot.evolutionCMA.Fitness(evolutionCMA)
  if(!is.na(save)){
    fname=paste(paste0(subdir,'CMAES'),'generation','log','fitness',extension,sep='.')
    ggsave(fname,p.fit,width = Width, height = Height.half, dpi = dpi, units = units)
  }
  last.evolutionCMA(evolutionCMA)

  plot.CMAPREF.timedependentWeights(input$problem, input$dimension)

  CDR.CMA <- do.call(rbind, lapply(c('6x5','10x10'), function(dim) {
    get.CDR.CMA(input$problems,dim) } ))
  p.tr=plot.CMABoxplot(CDR.CMA)
  if(!is.na(save)){
    fname=paste(paste0(subdir,'boxplot'),'CMAES',extension,sep='.')
    ggsave(fname,p.tr,width = Width, height = Height.half, dpi = dpi, units = units)
  }
  stat=ddply(CDR.CMA,~Problem+Dimension+ObjFun,function(x) summary(x$Rho))
  stat$Problem <- factorProblem(stat,F)
  print(xtable(stat),include.rownames = F)

  ks.CDR(CDR.CMA,'ObjFun',c('Problem','TrainingData','Timedependent','ObjFun'))
  ks.CDR(CDR.CMA,'Timedependent',c('Problem','TrainingData','Timedependent','ObjFun'))

  CDR.CMA.orlib <- do.call(rbind, lapply(c('6x5','10x10'), function(dim){
    get.CDR.CMA(input$problems,dim,times = F, testProblems = 'ORLIB') }))
  p.orb=plot.CMABoxplot(CDR.CMA.orlib)+theme(legend.position='none')
  if(!is.na(save)){
    fname=paste(paste0(subdir,'boxplot'),'CMAES','ORLIB',extension,sep='.')
    ggsave(fname,p.orb,width = Width, height = Height.half*0.95, dpi = dpi, units = units)
  }
  ks.CDR(CDR.CMA.orlib,'ObjFun',c('Problem','TrainingData','Timedependent','ObjFun'))

}

source('pref.stepwiseBias.R')
CDR.stepwiseBias<-get.CDR.stepwiseBias(input$problems,input$dimension)
plot.CDR.stepwiseBias(CDR.stepwiseBias)
stats.CDR.stepwiseBias(CDR.stepwiseBias)
