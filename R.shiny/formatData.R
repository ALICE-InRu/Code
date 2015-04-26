getAttribute<-function(str,regexpr.m,id,asStr=T){
  str=substr(str,attr(regexpr.m,'capture.start')[,id],attr(regexpr.m,'capture.start')[,id]+attr(regexpr.m,'capture.length')[,id]-1)
  if(asStr) return(str)
  return(as.numeric(str))
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
  return(getAttribute(Dimension,m,1,F)*getAttribute(Dimension,m,2,F))
}

factorSet <- function(Set){ return(factor(Set, levels=c('train','test'))) }

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
  lvs=c(sdrs,'OPT','RND','ALL')
  x$Extended=grepl('EXT',x$Track)
  ix=grepl('IL', x$Track)
  if(any(ix)){
    m=regexpr('IL(?<Iter>[0-9]+)(?<Supervision>[A-Z]+)',x$Track[ix],perl=T)
    x$Iter=0
    x$Iter[ix]=getAttribute(x$Track[ix],m,1,F)
    x$Supervision='Fixed'
    x$Supervision[ix]=getAttribute(x$Track[ix],m,2)

    lvs=c(lvs,paste0('IL',1:max(x$Iter)))
  }
  x$Track=factor(x$Track, levels=lvs)
  droplevels(x)
}

factorSDR <- function(SDR, simple=T){
  if(simple) { lbs=sdrs } else { lbs = c('Shortest Processing Time','Largest Processing Time','Least Work Remaining','Most Work Remaining') }
  droplevels(factor(SDR,levels=sdrs, labels=lbs))
}

factorRho <- function(x, var='Makespan'){
  x <- join(x,dataset.OPT[,c('Name','Optimum')],by='Name',type='left')
  return(round((x[,var]-x$Optimum)/x$Optimum*100,2))
}

factorFeature <- function(Feature,simple=T,phis=F){
  # remove 'phi.' from variable name (cleaner)
  if(length(grep('phi',Feature))>0){Feature=substr(Feature,5,100)}
  if(any(grepl('macfree',Feature))){ Feature[grepl('macfree',Feature)]='macFree' }
  if(any(grepl('totproc',Feature))){ Feature[grepl('totproc',Feature)]='totalProc' }
  if(any(grepl('totProc',Feature))){ Feature[grepl('totProc',Feature)]='totalProc' }
  if(any(grepl('arrivalTime',Feature))){ Feature[grepl('arrivalTime',Feature)]='arrival' }

  lvs=c('proc','startTime','endTime','arrival','totalProc','wait','wrmJob','jobOps','mac','macFree','wrmMac','macOps','slotReduced','slots','slotsTotal','makespan','wrmTotal','step',sdrs,'RNDmean','RNDstd','RNDmin','RNDmax')
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
