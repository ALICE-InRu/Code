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

  if(any(attr(m,"match.length")>0)){
    x$Problem=getAttribute(x$Name,m,'Problem')
    x$Dimension=getAttribute(x$Name,m,'Dimension')
    x$Set=factorSet(getAttribute(x$Name,m,'Set'))
    x$PID=getAttribute(x$Name,m,'PID',F)
    x$Dimension = factorDimension(x)
  } else {
    m=regexpr("(?<Problem>[j|f]sp.orlib).test.(?<PID>[0-9]+)", x$Name, perl = T)
    x$Problem=getAttribute(x$Name,m,'Problem')
    x$Set=factorSet(rep('test',nrow(x)))
    x$PID=getAttribute(x$Name,m,'PID',F)
    x <- factorORLIB(x)
  }
  x$Problem = factorProblem(x)
  return(x)
}

factorProblem <- function(x, simple=T, Problem='Problem'){
  if(Problem!='Problem'){ x$Problem=x[,grep(Problem,colnames(x))] }

  if('Shop' %in% names(x) & 'Distribution' %in% names(x)) {
    x$Problem=interaction(x$Shop,x$Distribution)
  }
  x$Problem=factor(x$Problem, levels=c('j.rnd','j.rndn','j.rnd_p1mdoubled','j.rnd_pj1doubled',
                                         'f.rnd','f.rndn','f.jc','f.mc','f.mxc','jsp.orlib','fsp.orlib'))
  if(!simple) levels(x$Problem)=c('j.rnd','j.rndn','j.rnd,J1','j.rnd,M1','f.rnd','f.rndn','f.jc','f.mc','f.mxc',
                                  'JSP.ORLIB','FSP.ORLIB')
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

factorCMAObjFun <- function(objFuns){
  return(droplevels(factor(objFuns, levels=c('MinimumMakespan','MinimumRho'), labels=c('min Cmax','min Rho'))))
}

factorRank <- function(Rank,simple=T){
  if(simple) { lbs=c('p','f','b','a')
  } else  {lbs=c('partial subsequent','full subsequent','base','all')}
  droplevels(factor(Rank, levels=c('p','f','b','a'), labels=lbs)) }

factorTrack <- function(x){
  isDf = is.data.frame(x)
  if(!isDf){ x=data.frame(Track=x) }
  x$Track = as.character(x$Track)

  lvs=c(sdrs,'OPT')
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
    x$Track[ix]=paste0('DA',x$Iter[ix])
    lvs=c(lvs,paste0('DA',1:max(x$Iter)))
    ix=x$Track=='OPT'
    if(any(ix)){ x$Supervision[ix]='FIXSUP' }
    x$Supervision=factor(x$Supervision, levels=c('FIXSUP','SUP','UNSUP'),
                         labels = c('Fixed','Decreasing','Unsupervised'))
  }
  ix=grepl('LOCOPT', x$Track)
  if(any(ix)){
    PL=enc2utf8('OPT\U25B')
    x$Track[ix]=PL
    lvs=c(lvs,PL)
  }
  ix=grepl('CMA|ES', x$Track)
  if(any(ix)){
    ix=grepl('rho', x$Track, ignore.case = T)
    if(any(ix)){
      x$Track[ix]='ES.rho'
      lvs=c(lvs,'ES.rho')
    }
    ix=grepl('Cmax', x$Track, ignore.case = T)
    if(any(ix)){
      x$Track[ix]='ES.Cmax'
      lvs=c(lvs,'ES.Cmax')
    }
  }
  lvs=c(lvs,'ALL')
  x$Track=factor(x$Track, levels=lvs)
  x=droplevels(x)
  if(!isDf) return(levels(x$Track))
  return(x)
}

factorSDR <- function(SDR, simple=T){
  if(simple) { lbs=sdrs } else { lbs = c('Shortest Processing Time','Largest Processing Time','Least Work Remaining','Most Work Remaining','Random dispatches') }
  droplevels(factor(SDR,levels=sdrs, labels=lbs))
}

factorRho <- function(x, var='Makespan'){
  x <- join(x,dataset.OPT[,c('Name','Optimum')],by='Name',type='left')
  return(round((x[,var]-x$Optimum)/x$Optimum*100,2))
}

factorORLIB <- function(x){
  x <- join(x,dataset.OPT[,c('Name','GivenName')],by='Name',type='left')
  m=regexpr("(?<Name>[a-zA-Z]+)(?<PID>[0-9]+)", x$GivenName, perl = T)
  x$ORSet=factor(getAttribute(x$GivenName,m,'Name'),levels=c('abz','ft','la','orb','swv','yn','car','hel','reC'))
  x$ORPID=getAttribute(x$GivenName,m,'PID',F)
  return(x)
}

factorFeature <- function(Feature,simple=T,phis=F){
  # remove 'phi.' from variable name (cleaner)
  if(length(grep('phi',Feature))>0){Feature=substr(Feature,5,100)}

  lvs=c('proc','startTime','endTime','arrival','wait',
        'jobTotProcTime','jobWrm','jobOps','macFree',
        'macTotProcTime','macWrm','macOps',
        'reducedSlack','macSlack','allSlack','makespan',
        sdrs,'RNDmean','RNDstd','RNDmin','RNDmax')
  if(phis) return(paste('phi',Feature,sep='.'))

  Feature=factor(Feature, levels = lvs)
  if(!simple){
    skip=grep('RND$',lvs)
    levels(Feature)[1:(skip-1)]=paste(1:(skip-1),lvs[1:(skip-1)],sep=') ')
    levels(Feature)[(skip+1):length(lvs)]=paste(skip:(length(lvs)-1),lvs[(skip+1):length(lvs)],sep=') ')
  }
  return(droplevels(Feature))
}

factorFeatureType <- function(Feature){
  m=regexpr('(?<Global>[A-Z]{3})',Feature,perl=T)
  Type=factor(ifelse(attr(m,'capture.start')!=-1,'Global','Local'),
              levels=c('Local','Global'))
  return(Type)
}


factorExplanatory <- function(Explanatory,simple=T,xis=F){
  # remove 'xi.' from variable name (cleaner)
  if(length(grep('xi',Explanatory))>0){Explanatory=substr(Explanatory,4,100)}

  lvs=c('step','totProcTime','totWrm')
  if(xis) return(paste('xi',Explanatory,sep='.'))

  Explanatory=factor(Explanatory, levels = lvs)
  if(!simple){
    levels(Explanatory)=paste(1:length(lvs),lvs,sep=') ')
  }
  return(droplevels(Explanatory))
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
