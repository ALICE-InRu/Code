getBWCaseScenario <- function(pat){
  allDat=getfilesTraining(useDiff = F,pattern = pat,Global = F)
  allDat=subset(allDat,Rho>0)
  stat=stepwise.Stat(allDat)
  stat$Shop=factor(substr(stat$Problem,1,1),levels=c('j','f'),labels=c('JSP','FSP'))
  stat$Track=factor(stat$Track,levels='OPT',labels=('mean best and worst case scenario'))
  return(stat)
}

findStepwiseOptimality <- function(problems,dim,track='OPT'){

  findSingleStepwiseOptimality <- function(problem){
    fname=paste('../trainingData/stepwise',problem,dim,track,'csv',sep='.')

    if(file.exists(fname)){ split=read.csv(fname) } else {
      dat=getfilesTraining(useDiff = F,pattern = paste(problem,dim,track,sep='.'),Global = F)
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
    stats=formatData(stats)

    return(list('Stats'=stats,'Raw'=split))
  }

  Stepwise=list('Stats'=NULL,'Raw'=NULL)

  for(problem in problems){
    tmp=findSingleStepwiseOptimality(problem)
    Stepwise$Raw=rbind(Stepwise$Raw,tmp$Raw)
    Stepwise$Stats=rbind(Stepwise$Stats,tmp$Stats)
  }
  return(Stepwise)
}

stepwise.Stat <- function(dat){

  split=ddply(dat,~Problem+Dimension+Step+PID+Track,summarise,
              best=min(Rho),
              worst=max(Rho),
              mu=mean(Rho),
              .progress = "text")

  #  BW = melt(split,measure.vars = colnames(split)[grep('best|worst',colnames(split))], variable.name = 'casescenario')
  #  stat=ddply(BW,~Problem+Track+Step+casescenario,summarise,mu=mean(value),Q1=quantile(value,.025),Q3=quantile(value,.75))

  stat=ddply(split,~Problem+Track+Step,summarise,best.mu=mean(best),worst.mu=mean(worst),mu=mean(mu))

  return(formatData(stat))
}

findStepwiseExtremal <- function(problems,dim){

  findSingleStepwiseExtremal <- function(problem){

    fname=paste(paste('../trainingData','stepwise',sep='/'),problem,dim,'OPT','extremal','csv',sep='.')

    if(file.exists(fname)){ split=read.csv(fname) } else {
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
    tmp=findSingleStepwiseExtremal(problem)
    Extremal$Raw=rbind(Extremal$Raw,tmp$Raw)
    Extremal$Stats=rbind(Extremal$Stats,tmp$Stats)
  }
  return(Extremal)
}

plotStepwiseUniqueness <- function(Stepwise,smooth){
  probs=unique(Stepwise$Stats$Problem)
  p=ggplot(Stepwise$Stats,aes(x=Step,y=unique.mu,color=Problem,fill=Problem))
  if(smooth){
    p=p+geom_smooth(aes(fill=Problem),size=1,alpha=0.1)+ggplotFill('Problem',length(probs))
  } else {
    p=p+geom_line(size=1)
  }
  p=p+
    ggplotColor('Problem',length(probs))+
    ggplotCommon(Stepwise$Stats,ylab='Number of unique optimal dispatches')
  return(p)
}

plotStepwiseOptimality <- function(Stepwise,simple,smooth){
  problems=unique(Stepwise$Stats$Problem)
  if(simple){
    p=ggplot(Stepwise$Stats,aes(x=Step,order=Problem))+geom_line(aes(y=rnd.mu),linetype='dashed',color='black',guide='none')
  } else {
    p=ggplot(Stepwise$Stats,aes(x=Step,y=rnd.mu,color=Problem,fill=Problem))
    if(smooth){
      p=p+geom_smooth(aes(fill=Problem),size=1,alpha=0.1)+ggplotFill('Problem',length(problems))
    } else {
      p=p+geom_line(size=1)
    }
  }
  p=p+ggplotColor('Problem',length(problems))+ggplotCommon(Stepwise$Stats,ylab='Probability of choosing optimal move')
  return(p)
}

plotStepwiseBestWorst <- function(dim,problems,onlyOPT){
  if(onlyOPT){
    pat=paste(paste('(',paste(problems,collapse='|'),')',sep=''),dim,'OPT',sep='.')
    stat=getBWCaseScenario(pat)

    p = ggplot(stat, aes(x=Step))+
      ggplotColor(name='Problem',num=length(unique(stat$Problem)))+
      ggplotFill(name='Problem',num=length(unique(stat$Problem)))+
      facet_grid(Track~Shop)

    p=p+geom_ribbon(aes(ymin=best.mu,ymax=worst.mu,fill=Problem,color=Problem),alpha=0.2)
    p=p+geom_line(aes(y=mu,color=Problem),size=1,linetype='dashed')

  } else {
    pat=paste(paste('(',paste(problems[1],collapse='|'),')',sep=''),dim,'(OPT|SPT|LPT|MWR|LWR)',sep='.')
    print(pat)
    allDat=getfilesTraining(useDiff = F,pattern = pat, Global = F)
    if(is.null(allDat)){ return(NULL) }
    allDatNotF=subset(allDat, (Track!='OPT' & Followed==F) | (Track=='OPT' & Rho>0))

    stat=stepwise.Stat(allDatNotF)
    stat.followed=stepwise.Stat(subset(allDat,Followed==T))

    p = ggplot(stat, aes(x=Step))+
      ggplotColor(name='Trajectory',num=length(unique(stat$Track)))+
      ggplotFill(name='Trajectory',num=length(unique(stat$Track)))+
      facet_grid(Problem~.)

    p=p+geom_ribbon(aes(ymin=best.mu,ymax=worst.mu,fill=Track,color=Track),alpha=0.5)
    p=p+geom_line(data=stat.followed,aes(y=best.mu,color=Track),size=1,linetype='dashed')
  }
  p=p+ggplotCommon(stat,ylabel=rhoLabel)
  return(p)
}

plotStepwiseSDR.wrtOPT <- function(Stepwise,Extremal,smooth){

  SDR=subset(Extremal$Raw, Feature=='proc' | Feature=='wrmJob')
  SDR$SDR[SDR$Feature=='proc' & SDR$Extremal=='min']='SPT'
  SDR$SDR[SDR$Feature=='proc' & SDR$Extremal=='max']='LPT'
  SDR$SDR[SDR$Feature=='wrmJob' & SDR$Extremal=='min']='LWR'
  SDR$SDR[SDR$Feature=='wrmJob' & SDR$Extremal=='max']='MWR'

  SDR=formatData(SDR)

  p=plotStepwiseOptimality(Stepwise,T,smooth) # random guessing

  if(smooth){
    p=p+geom_smooth(data=SDR,aes(y=value,color=SDR,fill=SDR,size='OPT'))+ggplotFill('SDR',4)
  } else {
    stat=ddply(SDR,~Problem+Step+SDR,summarise,mu=mean(value))
    p=p+geom_line(data=stat,aes(y=mu,color=SDR,size='OPT'))
  }

  p=p+ggplotColor('SDR',4)+facet_grid(Problem~.)+
    ggplotCommon(dat = SDR, probability = T,ylabel = 'Probability of SDR being optimal')

  p=p+scale_size_discrete(guide = FALSE)

  return(p)
}

plotStepwiseSDR.wrtTrack <- function(Stepwise,Extremal,problems,dim,smooth){

  spt=findStepwiseOptimality(problems,dim,'SPT')$Stats; spt$Track='SPT'
  lpt=findStepwiseOptimality(problems,dim,'LPT')$Stats; lpt$Track='LPT'
  lwr=findStepwiseOptimality(problems,dim,'LWR')$Stats; lwr$Track='LWR'
  mwr=findStepwiseOptimality(problems,dim,'MWR')$Stats; mwr$Track='MWR'

  SDR=rbind(spt,lpt,lwr,mwr)
  SDR=formatData(SDR)

  p=plotStepwiseSDR.wrtOPT(Stepwise,Extremal,F)
  p=p+geom_line(data=SDR,aes(y=rnd.mu,color=Track,size='SDR'))
  p=p+facet_wrap(~Problem,ncol=2)
  p=p+theme(legend.position = c(1, 0),
            legend.justification = c(1,0),
            legend.margin=unit(0,"lines"), legend.box="horizontal",
            legend.key.size=unit(1,"lines"), legend.text.align=0,
            legend.title.align=0)
  p=p+scale_size_manual('Track', values=c(0.5,1.2))

  return(p)
}

plotStepwiseExtremal <- function(Stepwise,Extremal,smooth){

  p=plotStepwiseOptimality(Stepwise,T,smooth) # random guessing

  if(smooth){
    p=p+geom_smooth(data=Extremal$Raw,aes(y=value,color=Extremal,fill=Extremal))+scale_fill_brewer(palette = 'Set1')
  } else {
    p=p+geom_line(data=Extremal$Stats,aes(y=Extremal.mu,color=Extremal))
  }

  p=p+facet_wrap(~Featurelbl,ncol=3)+scale_color_brewer(palette = 'Set1')+
    ggplotCommon(dat = Extremal$Stats, probability = T,
                 ylabel = expression('Probability of extremal feature '* ~ phi[i] * ~ ' being optimal'))

  return(p)
}

plotStepwiseFeatures <- function(problem,dim,global){

  plotOne <- function(stat,Type){
    stat=subset(stat,FeatureType==Type)
    p=ggplot(stat,aes(x=Step,color=Track,fill=Track))+
      geom_line(data=stat,aes(y=mu),size=1)+
      facet_wrap(~Featurelbl,ncol = 4, scales = 'free_y')+
      ggplotCommon(dat = stat,
                   xlabel = ifelse(Type=='Local','','step'),
                   ylabel = paste(Type,'features'))+
      ggplotColor(name='Trajectory',num=length(unique(stat$Track)))
    if(Type=='Local'){p=p+theme(legend.position='none')}
    return(p)
  }

  p=NULL
  trdat=getfilesTraining(useDiff = F,Global = global,pattern = paste(problem,dim,'(OPT|SPT|LPT|MWR|LWR|RND)',sep='.'))

  phix=grep('phi',colnames(trdat))
  trdat[,phix]=apply(trdat[,phix], MARGIN = 2, FUN = function(X) 2*(X - min(X))/diff(range(X))-1)

  print(summary(trdat[,phix]))

  trdat=subset(trdat,Followed==T)

  mdat=melt(trdat,measure.vars = colnames(trdat)[phix], variable.name = 'Feature')

  stat=ddply(mdat,~Problem+Feature+Step+Track,summarise,mu=mean(value),.progress = 'text')
  stat=formatData(stat)

  if(global)
    p=plotOne(stat,'Global')
  else
    p=plotOne(stat,'Local')+scale_y_continuous(breaks=seq(-1, 1, 1))

  p=p+ggtitle(expression('Evolution of feature ' * ~ bold(phi)))

  #pLocal=plotOne(stat,'Local')+scale_y_continuous(breaks=seq(-1, 1, 1))
  #pGlobal=plotOne(stat,'Global')
  #require(gridExtra)
  #pdf(fname,width = Width, height = Height.full)
  #grid.arrange(pLocal, pGlobal, ncol=1)
  #dev.off()

  return(p)
}
