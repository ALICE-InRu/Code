plot.StepwiseExtremal <- function(StepwiseOptimality,StepwiseExtremal,smooth,save=NA){
  if(length(StepwiseOptimality$Stats)==0) return(NULL)

  p=plot.stepwiseOptimality(StepwiseOptimality,T,smooth) # random guessing

  if(smooth){
    StepwiseExtremal$Raw$Feature=factorFeature(StepwiseExtremal$Raw$Feature,F)
    p=p+geom_smooth(data=StepwiseExtremal$Raw,method='loess',
                    aes(y=value,color=Extremal,fill=Extremal))+
      scale_fill_brewer(palette = 'Set1')
  } else {
    StepwiseExtremal$Stats$Feature=factorFeature(StepwiseExtremal$Stats$Feature,F)
    p=p+geom_line(data=StepwiseExtremal$Stats,aes(y=Extremal.mu,color=Extremal))
  }

  p=p+facet_wrap(~Feature,ncol=3)+scale_color_brewer(palette = 'Set1')+
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

  fname=paste('../stepwise/evolution',problem,dim,'csv',sep='.')
  if(file.exists(fname)) {
    stat = read.csv(fname)
  } else {
    trdatL=get.files.TRDAT(problem,dim,'ALL')
    if(is.null(trdatL)){return(NULL)}
    trdatG=get.files.TRDAT(problem,dim,'ALL',Global=T)
    trdat=join(trdatL,trdatG,by=colnames(trdatG)[colnames(trdatG) %in% colnames(trdatL)])

    phix=grep('phi',colnames(trdat))
    trdat[,phix]=apply(trdat[,phix], MARGIN = 2, FUN = function(X) 2*(X - min(X))/diff(range(X))-1)
    print(summary(trdat[,phix]))
    trdat=subset(trdat,Followed==T)
    mdat=melt(trdat,measure.vars = colnames(trdat)[phix], variable.name = 'Feature')
    stat=ddply(mdat,~Problem+Feature+Step+Track,summarise,mu=mean(value),.progress = 'text')
    write.csv(stat,file = fname, row.names = F, quote = F)
  }
  stat=factorTrack(stat)
  stat$Feature=factorFeature(stat$Feature)
  return(stat)
}

plot.StepwiseFeatures <- function(problem,dim,local,global,save=NA){

  stat = get.StepwiseFeatures(problem,dim)
  if(is.null(stat)) { return(NULL) }

  plotOne <- function(stat,Type){
    stat=subset(stat,FeatureType==Type)
    if(all(is.na(stat$mu))) { return(NULL) }

    p=ggplot(stat,aes(x=Step,color=Track,fill=Track))+
      geom_line(aes(y=mu),size=1)+
      facet_wrap(~Feature,ncol = 4, scales = 'free_y')+
      xlab(ifelse(Type=='Local','','step'))+
      ylab(paste(Type,'features'))+
      ggplotColor(name='Trajectory',num=length(unique(stat$Track)))+
      axisStep(dim)+axisCompact

    if(Type=='Local'){p=p+theme(legend.position='none')}
    p=p+ggtitle(expression('Evolution of feature ' * ~ bold(phi)))
    return(p)
  }

  stat$Feature = factorFeature(stat$Feature,F)
  m=regexpr('(?<Global>[A-Z]{3})',stat$Feature,perl=T)
  stat$FeatureType=factor(ifelse(attr(m,'capture.start')!=-1,'Global','Local'),
                          levels=c('Local','Global'))
  p=NULL
  if(global & local){
    pLocal=plotOne(stat,'Local')
    pGlobal=plotOne(stat,'Global')+ggtitle('')
    require(gridExtra)
    if(save) pdf(fname,width = Width, height = Height.full)
    grid.arrange(pLocal, pGlobal, ncol=1)
    if(save) dev.off()
    return(NULL)
  } else if(global)
    p=plotOne(stat,'Global')
  else
    p=plotOne(stat,'Local')

  if(!is.na(save)){
    problem=stat$Problem[1]
    dim=stat$Dimension[1]
    fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'Track','evolution',ifelse(local & global, 'ALL', ifelse(global,'Global','Local')),extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}
