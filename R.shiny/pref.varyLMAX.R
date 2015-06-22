create.prefModel.varyLMAX <- function(problem,dim,track,rank,stepSize=50000){
  bias='equal'
  timedependent=F
  all.trdat <- liblinear.pref.TRDAT(problem,dim,formatTrack(track,problem,dim,rank),rank)
  Bias = get.stepwiseBias(all.trdat$STEP, problem, dim, bias)

  fullSet <- length(all.trdat$Y)
  for(lmax in c(seq(stepSize,fullSet,stepSize),fullSet)){
    smpl=sample(fullSet, lmax, replace=T, prob=Bias)
    print(paste('lmax',length(smpl),':',round(length(unique(smpl))/length(smpl)*100,0),'% uniqueness'))
    trdat=all.trdat
    if(lmax<fullSet){
      trdat$X=all.trdat$X[smpl,]
      trdat$Y=all.trdat$Y[smpl]
      trdat$PID=all.trdat$PID[smpl]
      trdat$STEP=all.trdat$STEP[smpl]
    }
    create.prefModel(problem,dim,track,rank,bias,timedependent,F,0,trdat)
  }
}

CDR.prefModel.varyLMAX <- function(problem,dim,track,rank){
  bias='equal'
  timedependent=F
  CDR <- get.CDR(get.CDR.file_list(problem,dim,track,rank,timedependent,bias,T))
  CDR$Default <- CDR$lmax==sizePreferenceSet(dim,timedependent)
  return(CDR)
}

plot.prefModel.varyLMAX <- function(CDR){
  #CDR <- CDR.prefModel.varyLMAX(problem,dim,track,rank)
  CDR$lmax <- as.factor(CDR$lmax)
  p <- pref.boxplot(CDR,SDR=NULL,'Default',xVar='lmax','Default')
  return(p)
}

stats.prefModel.varyLMAX <- function(CDR){
  stat <- rho.statistic(CDR,c('Track','Extended','Supervision','Iter','lmax','Default'))
  stat <- arrange(stat, Training.Rho, Test.Rho) # order w.r.t. lowest mean
  return(stat)
}


