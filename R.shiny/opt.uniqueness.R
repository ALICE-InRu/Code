get.StepwiseOptimality <- function(problems,dim,track='OPT'){

  get.StepwiseOptimality1 <- function(problem){
    fname=paste('../stepwise/optimality',problem,dim,track,'csv',sep='.')

    if(file.exists(fname)){ split=read.csv(fname) } else {
      dat=get.files.TRDAT(problem, dim, track)
      if(is.null(dat)){ return(NULL) }
      dat$isOPT=dat$Rho==0

      split=ddply(dat,~Problem+Step+PID,summarise,
                  rnd=mean(isOPT),
                  unique=sum(isOPT),
                  .progress = "text")

      write.csv(split,file=fname,row.names=F,quote=F)
    }

    stats=ddply(split,~Problem+Step,summarise,
                rnd.mu=mean(rnd),
                rnd.Q1=quantile(rnd,.25),
                rnd.Q3=quantile(rnd,.75),
                unique.mu=mean(unique))

    if(max(stats$Step)<numericDimension(dim)){
      lastRow=stats[1,]
      lastRow$rnd.mu=1
      lastRow$rnd.Q1=1
      lastRow$rnd.Q3=1
      lastRow$unique.mu=1
      lastRow$Step=numericDimension(dim)
      stats=rbind(stats,lastRow)
    }
    return(list('Stats'=stats,'Raw'=split))
  }

  Stepwise=list('Stats'=NULL,'Raw'=NULL)

  for(problem in problems){
    tmp=get.StepwiseOptimality1(problem)
    if(!is.null(tmp)){
      Stepwise$Raw=rbind(Stepwise$Raw,tmp$Raw)
      Stepwise$Stats=rbind(Stepwise$Stats,tmp$Stats)
    }
  }

  if(!is.null(Stepwise$Stats)){
    Stepwise$Raw$Problem=factorProblem(Stepwise$Raw)
    Stepwise$Stats$Problem=factorProblem(Stepwise$Stats)
  } else { return(NULL) }

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
  dim=StepwiseOptimality$Stats$Dimension[1]

  p=p+ggplotColor('Problem',length(probs))+
    ylab('Number of unique optimal dispatches')+
    axisStep(dim)+axisCompact

  if(!is.na(save)){
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

  dim=StepwiseOptimality$Stats$Dimension[1]

  p=p+ylab('Probability of choosing optimal move')+
    axisStep(dim)+axisProbability

  if(!is.na(save)){
    fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT',extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

