stat.StepwiseExtremal <- function(problems,dim){

  stat.StepwiseExtremal1 <- function(problem){

    fname=paste('../trainingData/features/extremal',problem,dim,'csv',sep='.')

    if(file.exists(fname)){ split=read.csv(fname)
    } else {
      allDat=getfilesTraining(useDiff = F,pattern = paste(problem,dim,'OPT',sep='.'),Global = T)
      if(is.null(allDat)){return(NULL)}

      mdat=melt(allDat, measure.vars = colnames(allDat)[grep('phi',colnames(allDat))], variable.name = 'Feature')

      split=NULL
      for(phi in levels(mdat$Feature)){ # cannot apply ddply on 10x10 all at once (out of memory)
        tmp=ddply(subset(mdat,Feature==phi),~Problem+Dimension+Step+PID+Feature,summarise,
                  max=mean(isOPT[value==max(value)]),
                  min=mean(isOPT[value==min(value)]),
                  .progress = "text")

        split=rbind(split,tmp)
      }

      write.csv(split,file=fname,row.names=F,quote=F)
    }

    split=subset(split,Feature != 'phi.step' & Feature != 'phi.wrmTotal') # min == max

    mdat=melt(split,measure.vars = c('min','max'),variable.name = 'Extremal')

    stats=ddply(mdat,~Problem+Dimension+Step+Feature+Extremal,summarise,Extremal.mu=mean(value))

    return(list('Stats'=formatData(stats),'Raw'=formatData(mdat)))

  }

  Extremal=list('Stats'=NULL,'Raw'=NULL)

  for(problem in problems){
    tmp=stat.StepwiseExtremal1(problem)
    Extremal$Raw=rbind(Extremal$Raw,tmp$Raw)
    Extremal$Stats=rbind(Extremal$Stats,tmp$Stats)
  }
  return(Extremal)
}

plot.StepwiseSDR.wrtOPT <- function(StepwiseOptimality,StepwiseExtremal,smooth,save=NA){

  SDR=subset(StepwiseExtremal$Raw, Feature=='proc' | Feature=='wrmJob')
  SDR$SDR[SDR$Feature=='proc' & SDR$Extremal=='min']='SPT'
  SDR$SDR[SDR$Feature=='proc' & SDR$Extremal=='max']='LPT'
  SDR$SDR[SDR$Feature=='wrmJob' & SDR$Extremal=='min']='LWR'
  SDR$SDR[SDR$Feature=='wrmJob' & SDR$Extremal=='max']='MWR'

  SDR=formatData(SDR)

  p=plot.stepwiseOptimality(StepwiseOptimality,T,smooth) # random guessing

  if(smooth){
    p=p+geom_smooth(data=SDR,aes(y=value,color=SDR,fill=SDR,size='OPT'))+ggplotFill('SDR',4)
  } else {
    stat=ddply(SDR,~Problem+Step+SDR,summarise,mu=mean(value))
    p=p+geom_line(data=stat,aes(y=mu,color=SDR,size='OPT'))
  }

  p=p+ggplotColor('SDR',4)+
    facet_grid(Problem~.)+
    ylab('Probability of SDR being optimal')

  if(!is.na(save)){
    dim=ifelse(length(levels(StepwiseOptimality$Stats$Dimension))>1,'ALL',StepwiseOptimality$Stats$Dimension[1])
    fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','casescenario',extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

plot.StepwiseSDR.wrtTrack <- function(StepwiseOptimality,StepwiseExtremal,dim,smooth,lastStep=-1,save=NA){
  if(is.null(StepwiseOptimality)|is.null(StepwiseExtremal)) {return(NULL)}

  problems=unique(StepwiseOptimality$Stats$Problem)
  SDR=NULL
  for(sdr in sdrs){
    tmp=stat.StepwiseOptimality(problems,dim,sdr,lastStep)$Stats
    if(!is.null(tmp)){
      tmp$Track=sdr
      SDR=rbind(SDR,tmp)
    }
  }

  p=plot.StepwiseSDR.wrtOPT(StepwiseOptimality,StepwiseExtremal,F)
  if(!is.null(SDR)){
    SDR=formatData(SDR)
    p=p+geom_line(data=SDR,aes(y=rnd.mu,color=Track,size='SDR'))
    p=p+scale_size_manual('Track', values=c(0.5,1.2))
  }

  if(!is.na(save)){
    dim=ifelse(length(levels(StepwiseOptimality$Stats$Dimension))>1,'ALL',StepwiseOptimality$Stats$Dimension[1])
    fname=ifelse(length(problems)>1,
                 paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','SDR','TRACK',extension,sep='.'),
                 paste(paste(subdir,problems,'stepwise',sep='/'),dim,'OPT','SDR','TRACK',extension,sep='.'))

    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}
