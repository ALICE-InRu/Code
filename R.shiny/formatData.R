getAttribute<-function(str,regexpr.m,name,asStr=T){
  names=attr(regexpr.m,"capture.names")
  id=which(names==name)
  str=substr(str,attr(regexpr.m,'capture.start')[,id],attr(regexpr.m,'capture.start')[,id]+
               attr(regexpr.m,'capture.length')[,id]-1)
  if(asStr) return(str)
  return(as.numeric(str))
}

factorFromName <- function(x){
  m=regexpr("(?<Problem>[j|f].[a-z_1]+).(?<Dimension>[0-9]+x[0-9]+).(?<Set>train|test).(?<PID>[0-9]+)", x$Name, perl = T)
  x$Problem=getAttribute(x$Name,m,'Problem')
  x$Problem = factorProblem(x)
  x$Dimension=getAttribute(x$Name,m,'Dimension')
  x$Dimension = factorDimension(x)
  x$Set=factorSet(getAttribute(x$Name,m,'Set'))
  x$PID=getAttribute(x$Name,m,'PID',F)
  return(x)
}

factorProblem <- function(x, simple=T){
  if('Shop' %in% names(x) & 'Distribution' %in% names(x) ) {
    x$Problem=interaction(x$Shop,x$Distribution)
  }
  x$Problem=factor(x$Problem, levels=c('j.rnd','j.rndn','j.rnd_p1mdoubled','j.rnd_pj1doubled','f.rnd','f.rndn','f.jc','f.mc','f.mxc'))
  if(!simple) levels(x$Problem)=c('j.rnd','j.rndn','j.rnd, J1','j.rnd, M1','f.rnd','f.rndn','f.jc','f.mc','f.mxc')
  return(droplevels(x$Problem))
}

numericDimension <- function(Dimension){
  m=regexpr('(?<NumJobs>[0-9]+)x(?<NumMachines>[0-9]+)',Dimension,perl=T)
  return(getAttribute(Dimension,m,'NumJobs',F)*getAttribute(Dimension,m,'NumMachines',F))
}

factorSet <- function(Set){ return(factor(Set, levels=c('train','validation','test'))) }

factorDimension <- function(x){
  if('NumJobs' %in% names(x) & 'NumMachines' %in% names(x) ) {
    x$Dimension=paste(x$NumJobs,x$NumMachines,sep='x')
  }
  return(droplevels(factor(x$Dimension, levels=c('6x5','8x8','10x10','12x12','14x14'))))
}

factorRank <- function(Rank,simple=T){
  if(simple) { lbs=c('p','f','b','a')
  } else  {lbs=c('partial subsequent','full subsequent','base','all')}
  droplevels(factor(Rank, levels=c('p','f','b','a'), labels=lbs)) }

factorTrack <- function(x){
  lvs=c(sdrs,'OPT','ALL')
  x$Extended=grepl('EXT',x$Track)
  ix=grepl('EXT', x$Track)
  if(any(ix)){ x$Track[ix]=substr(x$Track[ix],1,stringr::str_length(x$Track[ix])-3) }

  ix=grepl('IL', x$Track)
  if(any(ix)){
    m=regexpr('IL(?<Iter>[0-9]+)(?<Supervision>[A-Z]+)',x$Track[ix],perl=T)
    x$Iter=0
    x$Iter[ix]=getAttribute(x$Track[ix],m,'Iter',F)
    x$Supervision='FIXSUP'
    x$Supervision[ix]=getAttribute(x$Track[ix],m,'Supervision')
    x$Track[ix]=paste0('IL',x$Iter[ix])
    lvs=c(lvs,paste0('IL',1:max(x$Iter)))
    ix=x$Track=='OPT'
    if(any(ix)){ x$Supervision[ix]='FIXSUP' }
    x$Supervision=factor(x$Supervision, levels=c('FIXSUP','SUP','UNSUP'),
                         labels = c('Fixed','Decreasing','Unsupervised'))
  }
  x$Track=factor(x$Track, levels=lvs)
  droplevels(x)
}

factorSDR <- function(SDR, simple=T){
  if(simple) { lbs=sdrs } else { lbs = c('Shortest Processing Time','Largest Processing Time','Least Work Remaining','Most Work Remaining','Random dispatches') }
  droplevels(factor(SDR,levels=sdrs, labels=lbs))
}

factorRho <- function(x, var='Makespan'){
  x <- join(x,dataset.OPT[,c('Name','Optimum')],by='Name',type='left')
  return(round((x[,var]-x$Optimum)/x$Optimum*100,2))
}

factorFeature <- function(Feature,simple=T,phis=F){
  # remove 'phi.' from variable name (cleaner)
  if(length(grep('phi',Feature))>0){Feature=substr(Feature,5,100)}
  #if(any(grepl('macfree',Feature))){ Feature[grepl('macfree',Feature)]='macFree' }
  #if(any(grepl('totproc',Feature))){ Feature[grepl('totproc',Feature)]='procTotal' }
  #if(any(grepl('totProc',Feature))){ Feature[grepl('totProc',Feature)]='procTotal' }
  #if(any(grepl('arrivalTime',Feature))){ Feature[grepl('arrivalTime',Feature)]='arrival' }

  lvs=c('proc','startTime','endTime','arrival','procTotal','wait','wrmJob','jobOps','mac','macFree','wrmMac','macOps','slotReduced','slots','slotsTotal','makespan','wrmTotal','step',sdrs,'RNDmean','RNDstd','RNDmin','RNDmax')
  if(phis) return(paste('phi',Feature,sep='.'))

  Feature=factor(Feature, levels = lvs)
  if(!simple){
      levels(Feature)=paste(1:length(lvs),lvs,sep=') ')
  }
  return(droplevels(Feature))
}

factorCDR <- function(x,useProb=F){
  if(useProb){
    return(interaction(x$NrFeat,x$Model,x$Prob))
  } else  {
    return(interaction(x$NrFeat,x$Model))
  }
}

factorFromCDR <- function(x){
  m=regexpr('F(?<NrFeat>[0-9]+).M(?<Model>[0-9]+)',x$CDR,perl=T)
  x$NrFeat=getAttribute(x$CDR,m,'NrFeat',F)
  x$Model=getAttribute(x$CDR,m,'Model',F)
  x$CDR=factorCDR(x)
  return(x)
}

factorBias <- function(Bias){
  Bias = factor(Bias, levels = c('equal','opt','bcs','wcs','dbl1st','dbl2nd'))
  return(droplevels(Bias))
}
