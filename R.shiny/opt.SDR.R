get.StepwiseExtremal <- function(problems,dim){

  get.StepwiseExtremal1 <- function(problem){

    fname=paste('../stepwise/extremal',problem,dim,'csv',sep='.')

    if(file.exists(fname)){ split=read.csv(fname)
    } else {
      trdatL=get.files.TRDAT(problem, dim, 'OPT', Global = F)
      trdatG=get.files.TRDAT(problem, dim, 'OPT', Global = T)
      trdat=join(trdatL,trdatG,by=colnames(trdatG)[colnames(trdatG) %in% colnames(trdatL)])

      if(is.null(trdat)){return(NULL)}
      trdat$isOPT=trdat$Rho==0

      mdat=melt(trdat, variable.name = 'Feature',
                measure.vars = colnames(trdat)[grep('phi',colnames(trdat))])

      split=NULL
      for(phi in levels(mdat$Feature)){ # cannot apply ddply on 10x10 all at once (out of memory)
        tmp=ddply(subset(mdat,Feature==phi),~Problem+Step+PID+Feature,summarise,
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

    return(list('Stats'=stats,'Raw'=mdat))

  }

  Extremal=list('Stats'=NULL,'Raw'=NULL)

  for(problem in problems){
    tmp=get.StepwiseExtremal1(problem)
    Extremal$Raw=rbind(Extremal$Raw,tmp$Raw)
    Extremal$Stats=rbind(Extremal$Stats,tmp$Stats)
  }
  Extremal$Raw$Feature=factorFeature(Extremal$Raw$Feature)
  Extremal$Stats$Feature=factorFeature(Extremal$Stats$Feature)

  return(Extremal)
}

plot.StepwiseSDR.wrtOPT <- function(StepwiseOptimality,StepwiseExtremal,smooth,save=NA){

  SDR=subset(StepwiseExtremal$Raw, Feature=='proc' | Feature=='wrmJob')
  SDR$SDR[SDR$Feature=='proc' & SDR$Extremal=='min']='SPT'
  SDR$SDR[SDR$Feature=='proc' & SDR$Extremal=='max']='LPT'
  SDR$SDR[SDR$Feature=='wrmJob' & SDR$Extremal=='min']='LWR'
  SDR$SDR[SDR$Feature=='wrmJob' & SDR$Extremal=='max']='MWR'

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

plot.StepwiseSDR.wrtTrack <- function(StepwiseOptimality,StepwiseExtremal,dim,smooth,save=NA){
  if(is.null(StepwiseOptimality)|is.null(StepwiseExtremal)) {return(NULL)}

  problems=levels(StepwiseOptimality$Stats$Problem)
  SDR=NULL
  for(sdr in sdrs){
    tmp=get.StepwiseOptimality(problems,dim,sdr)$Stats
    if(!is.null(tmp)){
      tmp$Track=sdr
      SDR=rbind(SDR,tmp)
    }
  }

  p=plot.StepwiseSDR.wrtOPT(StepwiseOptimality,StepwiseExtremal,F)
  if(!is.null(SDR)){
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
