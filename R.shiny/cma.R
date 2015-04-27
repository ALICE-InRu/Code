get.evolutionCMA <- function(problem,dim='6x5',timedependent=F){

  get.evolutionCMA1 <- function(type){
    file=paste('output',problem,dim,type,'weights',
               ifelse(timedependent,'timedependent','timeindependent'),'csv',sep='.')
    x <- read.csv(paste0('../CMAES/results/',file))
    pat='phi.(?<Feature>[a-zA-Z]+).1$' # only first step is showed regardless of timedependent
    x=melt(x[,c(1:3,grep(pat,names(x),perl=T))], id.vars=c('Generation','CountEval','Fitness'))
    m=regexpr(pat,x$variable,perl=T)
    x$Feature=factorFeature(getAttribute(x$variable,m,1))
    #x$Step=as.numeric(getAttribute(x$variable,m,2))
    x$Model=paste0('CMA-',type)
    return(x)
  }
  stat=rbind(get.evolutionCMA1('MinimumMakespan'),get.evolutionCMA1('MinimumRho'))
  return(stat)
}

plot.evolutionCMA.Weight <- function(evolutionCMA){

  x=ddply(evolutionCMA,~Model+Generation,mutate,sc.weight=value/sqrt(sum(value*value)))
  x$Feature=factorFeature(x$Feature,F)
  p=ggplot(x,aes(x=Generation,y=sc.weight,color=Model))+
    geom_line()+
    #geom_smooth(se=F, method='loess')+
    ggplotColor('Model',3)+axisCompact+facet_wrap(~Feature,nrow=4)
  return(p)


}

plot.timedependentWeights <- function(problem,dim='6x5',
                                      track='OPT',rank='p',probability='equal'){

  getPrefWeight <- function(){
    file=paste('/full',problem,dim,rank,track,probability,'weights.timedependent.csv',sep='.')
    w=subset(read.csv(paste0('../liblinear/',dim,file)),Type=='Weight')
    w$Model='PREF'
    w$mean=NULL; w$NrFeat=NULL; w$Type=NULL
    w=melt(w, id.vars = c('Model','Feature'), variable.name = 'Step')
    w$Step=as.numeric(substr(w$Step,6,10))
    return(w)
  }

  getCMAWeight <- function(type){
    file=paste('full',problem,dim,type,'weights.timedependent.csv',sep='.')
    w <- subset(read.csv(paste0('../CMAES/',file)),Type=='Weight')
    w$Model=paste0('CMA-',type)
    w$mean=NULL; w$NrFeat=NULL; w$Type=NULL
    w=melt(w, id.vars = c('Model','Feature'), variable.name = 'Step')
    w$Step=as.numeric(substr(w$Step,6,10))
    return(w)
  }

  w=rbind(getCMAWeight('MinimumMakespan'),
          getCMAWeight('MinimumRho'),
          getPrefWeight())

  w=ddply(w,~Step+Model,mutate,sc.weight=value/sqrt(sum(value*value)))
  w$Feature=factorFeature(w$Feature,F)
  p=ggplot(w,aes(x=Step,y=sc.weight,color=Model,shape=Model))+geom_point(alpha=0.1)+
    geom_smooth(se=F, method='loess')+ggplotColor('Model',3)+
    axisStep(w$Step)+axisCompact+facet_wrap(~Feature,nrow=4)
  return(p)
}



