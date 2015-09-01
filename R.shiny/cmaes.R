get.evolutionCMA <- function(problems,dim,Timedependent=T,Timeindependent=T,meanStep=F){
  get.evolutionCMA1 <- function(problem,type,timedependent){
    file=paste('output',problem,dim,type,'weights',
               ifelse(timedependent,'timedependent','timeindependent'),'csv',sep='.')
    file=paste0(DataDir,'CMAES/results/',file)
    if(!file.exists(file)) { return(NULL) }
    x <- read_csv(file)
    x=subset(x, Generation==1 | Generation %% 10 == 0 | Generation==max(Generation)) # otherwise too much data
    pat='phi.(?<Feature>[a-zA-Z]+).(?<Step>[0-9]+)'
    x=melt(x[,c(1:3,grep(pat,names(x),perl=T))], id.vars=c('Generation','CountEval','Fitness'))
    m=regexpr(pat,x$variable,perl=T)
    x$Step=getAttribute(x$variable,m,'Step',F)
    if(meanStep & timedependent){
      x=ddply(x,~Generation+CountEval+Fitness+variable,summarise,value=mean(value), .progress = 'text')
    } else { x=subset(x,Step==1)}
    x$Feature=factorFeature(getAttribute(x$variable,m,'Feature'))
    x$ObjFun=type
    return(x)
  }
  get.evolutionCMA2 <- function(problem,timedependent){
    stat=rbind(get.evolutionCMA1(problem,'MinimumMakespan',timedependent),
               get.evolutionCMA1(problem,'MinimumRho',timedependent))
    if(is.null(stat)) return(NULL)
    stat$Timedependent=timedependent
    stat$Problem=problem
    return(stat)
  }
  stat=NULL
  for(problem in problems){
    if(Timedependent) stat=rbind(stat,get.evolutionCMA2(problem,T))
    if(Timeindependent) stat=rbind(stat,get.evolutionCMA2(problem,F))
  }
  if(is.null(stat)) {return(NULL)}
  info=ddply(stat,~Problem+ObjFun+Timedependent,summarise,Generation=max(Generation),CountEval=max(CountEval))
  info=merge(tidyr::spread(info[,-4],'ObjFun','CountEval'),
             tidyr::spread(info[,-5],'ObjFun','Generation'),
             by=c('Problem','Timedependent'),
             suffixes = c(".CountEval",".Generation"))
  return(stat)
}

plot.evolutionCMA.Weights <- function(evolutionCMA,problem){
  x=subset(evolutionCMA,Problem==problem)
  x=ddply(x,~ObjFun+Generation+Timedependent,mutate,sc.weight=value/sqrt(sum(value*value)))
  x$Feature=factorFeature(x$Feature,F)
  p=ggplot(x,aes(x=Generation,y=sc.weight,color=ObjFun,linetype=Timedependent))+
    geom_line()+
    ggplotColor('Objective function',2)+axisCompact+facet_wrap(~Feature,nrow=4)
  return(p)
}

plot.evolutionCMA.Fitness <- function(evolutionCMA){
  evolutionCMA$Problem=factorProblem(evolutionCMA)
  x=evolutionCMA; x$value=NULL
  x=tidyr::spread(x,'ObjFun','Fitness')
  x=subset(x,!is.na(MinimumMakespan) & !is.na(MinimumRho))

  p1 <- ggplot(x,aes(x=Generation, y=MinimumRho, linetype = Timedependent)) +
    geom_line(color='grey') + ylab(expression("Minimum" * ~rho * ~" (%)")) +facet_wrap(~Problem,ncol=2)

  p2 <- ggplot(x, aes(Generation, y=MinimumMakespan, linetype = Timedependent)) +
    geom_line(color='black') + ylab(expression("Minimum" *~ C[max])) +facet_wrap(~Problem,ncol=2)

  cat(paste('MinimumRho=grey','MinimumMakespan=black',sep='\n'))

  grid_arrange_different_yaxis(p1,p2,length(unique(x$Problem)))
  #grid_arrange_shared_xaxis(p1,p2)
}

plot.CMAPREF.timedependentWeights <- function(problem,dim='6x5',
                                      track='OPT',rank='p',bias='equal'){

  getPrefWeight <- function(){
    file=paste('full',problem,dim,rank,track,bias,'weights.timedependent.csv',sep='.')
    w=read_csv(paste0(DataDir,'PREF/weights/',file))
    w=subset(w[,-5],Type=='Weight');
    w=tidyr::gather(w,'Step','value',grep('Step',names(w)))
    w$Step=as.numeric(substr(w$Step,6,10))
    w$Model='PREF'
    return(w)
  }

  getCMAWeight <- function(type){
    file=paste('full',problem,dim,type,'weights.timedependent.csv',sep='.')
    w <- subset(read_csv(paste0(DataDir,'CMAES/weights/',file)),Type=='Weight')
    w=subset(w[,-5],Type=='Weight');
    w=tidyr::gather(w,'Step','value',grep('Step',names(w)))
    w$Step=as.numeric(substr(w$Step,6,10))
    w$Model=paste0('CMA-',ifelse('MinimumMakespan'==type,'Cmax','Rho'))
    return(w)
  }

  w=rbind(getCMAWeight('MinimumMakespan'),
          getCMAWeight('MinimumRho'),
          getPrefWeight())

  w$Feature=factorFeature(w$Feature,F)
  w$Feature[w$Feature == levels(w$Feature)[5]] = levels(w$Feature)[17]
  w=ddply(w,~Step+Model,mutate,sc.weight=value/sqrt(sum(value*value)))

  p=ggplot(w,aes(x=Step,y=sc.weight,color=Model,shape=Model))+geom_point(alpha=0.1)+
    geom_smooth(se=F, method='loess')+ggplotColor('Model',3)+
    axisStep(dim)+axisCompact+facet_wrap(~Feature,ncol=4)
  return(p)
}

get.CDR.CMA <- function(problems,dim,timedependent,objFuns=c('MinimumRho','MinimumMakespan')){

  get.CDR1 <- function(problem,objFun) {
    dir=paste0(DataDir,'CMAES/CDR/',paste('full',problem,dim,objFun,'weights',ifelse(timedependent,'timedependent','timeindependent'),sep='.'))
    files=list.files(dir,paste(problem,dim,sep='.'))
    CDR = get.files(dir,files)
    CDR$ObjFun = objFun
    return(CDR)
  }

  CDR <- do.call(rbind, lapply(objFuns, function(objFun) { ldply(problems, get.CDR1, objFun)} ))

  CDR <- factorFromName(CDR)
  CDR$ObjFun <- as.factor(CDR$ObjFun)
  CDR$Rho <- factorRho(CDR)

  return(CDR)

}

plot.CMABoxplot <- function(CDR.CMA,SDR=NULL){
  pref.boxplot(CDR.CMA,SDR,'ObjFun',xText = 'CMA-ES objective function',tiltText = F)
}
