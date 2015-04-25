plot.StepwiseExtremal <- function(StepwiseOptimality,StepwiseExtremal,smooth,save=NA){
  if(length(StepwiseOptimality$Stats)==0) return(NULL)

  p=plot.stepwiseOptimality(StepwiseOptimality,T,smooth) # random guessing

  if(smooth){
    p=p+geom_smooth(data=StepwiseExtremal$Raw,aes(y=value,color=Extremal,fill=Extremal))+scale_fill_brewer(palette = 'Set1')
  } else {
    p=p+geom_line(data=StepwiseExtremal$Stats,aes(y=Extremal.mu,color=Extremal))
  }

  p=p+facet_wrap(~Featurelbl,ncol=3)+scale_color_brewer(palette = 'Set1')+
    ylab(expression('Probability of extremal feature '* ~ phi[i] * ~ ' being optimal'))

  if(!is.na(save)){
    problem=ifelse(length(levels(StepwiseOptimality$Stats$Problem))>1,'ALL',StepwiseOptimality$Stats$Problem[1])
    dim=ifelse(length(levels(StepwiseOptimality$Stats$Dimension))>1,'ALL',StepwiseOptimality$Stats$Dimension[1])
    fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'OPT','extremal',extension,sep='.')
    print(fname)
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

get.StepwiseFeatures <- function(problem,dim){

  fname=paste('../trainingData/features/evolution',problem,dim,'csv',sep='.')
  if(file.exists(fname)) {
    stat = read.csv(fname)
  } else {
    trdat=getTrainingDataRaw(problem,dim,'ALL',global=T)
    trdat=formatData(trdat)
    phix=grep('phi',colnames(trdat))
    trdat[,phix]=apply(trdat[,phix], MARGIN = 2, FUN = function(X) 2*(X - min(X))/diff(range(X))-1)
    print(summary(trdat[,phix]))
    trdat=subset(trdat,Followed==T)
    mdat=melt(trdat,measure.vars = colnames(trdat)[phix], variable.name = 'Feature')
    stat=ddply(mdat,~Problem+Feature+Step+Track,summarise,mu=mean(value),.progress = 'text')
    write.csv(stat,file = fname, row.names = F, quote = F)
 }
  return(formatData(stat))
}

plot.StepwiseFeatures <- function(problem,dim,local,global,save=NA){

  stat = get.StepwiseFeatures(problem,dim)

  plotOne <- function(stat,Type){
    stat=subset(stat,FeatureType==Type)
    p=ggplot(stat,aes(x=Step,color=Track,fill=Track))+
      geom_line(data=stat,aes(y=mu),size=1)+
      facet_wrap(~Featurelbl,ncol = 4, scales = 'free_y')+
      xlab(ifelse(Type=='Local','','step'))+
      ylab(paste(Type,'features'))+
      ggplotColor(name='Trajectory',num=length(unique(stat$Track)))+
      axisStep(stat$Step)+axisCompact

    if(Type=='Local'){p=p+theme(legend.position='none')}
    return(p)
  }

  p=NULL

  problem=stat$Problem[1]
  dim=stat$Dimension[1]
  fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'Track','evolution',ifelse(local & global, 'ALL', ifelse(global,'Global','Local')),extension,sep='.')

  if(!is.na(save)){
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  title=expression('Evolution of feature ' * ~ bold(phi))
  if(global & local){
    pLocal=plotOne(stat,'Local')+ggtitle(title)
    pGlobal=plotOne(stat,'Global')
    require(gridExtra)
    if(save) pdf(fname,width = Width, height = Height.full)
    grid.arrange(pLocal, pGlobal, ncol=1)
    if(save) dev.off()
    return(NULL)
  } else if(global)
    p=plotOne(stat,'Global')
  else
    p=plotOne(stat,'Local')

  p=p+ggtitle(title)

  return(p)
}
