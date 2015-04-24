stat.StepwiseOptimality <- function(problems,dim,track='OPT',LastStep=-1){

  stat.StepwiseOptimality1 <- function(problem){
    fname=paste('../trainingData/stepwise',problem,dim,track,'csv',sep='.')

    if(file.exists(fname)){ split=read.csv(fname) } else {
      dat=getfilesTraining(useDiff = F,pattern = paste(problem,dim,track,sep='.'),Global = F)
      if(is.null(dat)){ return(NULL) }
      dat$isOPT=dat$Rho==0

      split=ddply(dat,~Problem+Dimension+Step+PID,summarise,
                  rnd=mean(isOPT),
                  unique=sum(isOPT),
                  .progress = "text")

      write.csv(split,file=fname,row.names=F,quote=F)
    }

    stats=ddply(split,~Problem+Dimension+Step,summarise,
                rnd.mu=mean(rnd),
                rnd.Q1=quantile(rnd,.25),
                rnd.Q3=quantile(rnd,.75),
                unique.mu=mean(unique))

    if(max(stats$Step)<LastStep){
      lastRow=stats[1,]
      lastRow$rnd.mu=1
      lastRow$rnd.Q1=1
      lastRow$rnd.Q3=1
      lastRow$unique.mu=1
      lastRow$Step=LastStep
      stats=rbind(stats,lastRow)
    }

    stats=formatData(stats)

    return(list('Stats'=stats,'Raw'=split))
  }

  Stepwise=list('Stats'=NULL,'Raw'=NULL)

  for(problem in problems){
    tmp=stat.StepwiseOptimality1(problem)
    if(!is.null(tmp)){
      Stepwise$Raw=rbind(Stepwise$Raw,tmp$Raw)
      Stepwise$Stats=rbind(Stepwise$Stats,tmp$Stats)
    }
  }
  return(Stepwise)
}


plot.stepwiseUniqueness <- function(StepwiseOptimality,smooth,save=NA){
  if(is.null(StepwiseOptimality)) { return(NULL)}

  probs=levels(StepwiseOptimality$Stats$Problem)
  p=ggplot(StepwiseOptimality$Stats,aes(x=Step,y=unique.mu,color=Problem,fill=Problem))
  if(smooth){
    p=p+geom_smooth(aes(fill=Problem),size=1,alpha=0.1)+ggplotFill('Problem',length(probs))
  } else {
    p=p+geom_line(size=1)
  }
  p=p+ggplotColor('Problem',length(probs))+
    ylab('Number of unique optimal dispatches')+
    axisStep(StepwiseOptimality$Stats$Step)+axisCompact

  if(!is.na(save)){
    dim=ifelse(length(levels(StepwiseOptimality$Stats$Dimension))>1,'ALL',StepwiseOptimality$Stats$Dimension[1])
    fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','unique',extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

plot.stepwiseOptimality <- function(StepwiseOptimality,simple,smooth,save=NA){
  if(is.null(StepwiseOptimality)) { return(NULL)}

  problems=levels(StepwiseOptimality$Stats$Problem)
  if(simple){
    p=ggplot(StepwiseOptimality$Stats,aes(x=Step,order=Problem))+geom_line(aes(y=rnd.mu),linetype='dashed',color='black',guide='none')
  } else {
    p=ggplot(StepwiseOptimality$Stats,aes(x=Step,y=rnd.mu,color=Problem,fill=Problem))
    if(smooth){
      p=p+geom_smooth(aes(fill=Problem),size=1,alpha=0.1)+ggplotFill('Problem',length(problems))
    } else {
      p=p+geom_line(size=1)
    }
  }
  if(!simple)
    p=p+ggplotColor('Problem',length(problems))

  p=p+ylab('Probability of choosing optimal move')+
    axisStep(StepwiseOptimality$Stats$Step)+axisProbability

  if(!is.na(save)){
    dim=ifelse(length(levels(StepwiseOptimality$Stats$Dimension))>1,'ALL',StepwiseOptimality$Stats$Dimension[1])
    fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT',extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

