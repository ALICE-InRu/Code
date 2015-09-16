plot.StepwiseExtremal <- function(StepwiseOptimality,StepwiseExtremal,CDR=NULL,dim,smooth,save=NA){
  if(length(StepwiseOptimality$Stats)==0) return(NULL)

  p=plot.stepwiseOptimality(StepwiseOptimality,dim,T,smooth) # random guessing

  if(smooth){
    StepwiseExtremal$Raw$Feature=factorFeature(StepwiseExtremal$Raw$Feature,F)
    p=p+geom_smooth(data=StepwiseExtremal$Raw,method='loess',
                    aes(y=value,color=Extremal,fill=Extremal))+
      scale_fill_brewer(palette = 'Set1')
  } else {
    StepwiseExtremal$Stats$Feature=factorFeature(StepwiseExtremal$Stats$Feature,F)
    p=p+geom_line(data=StepwiseExtremal$Stats,aes(y=Extremal.mu,color=Extremal))
  }

  p=p+facet_wrap(~Feature,ncol=4)+scale_color_brewer(palette = 'Set1')+
    ylab(expression('Probability of extremal feature '* ~ phi[i] * ~ ' being optimal'))

  if(!is.null(CDR)){
      stats <- ddply(CDR,~Problem+Dimension+Feature+Extremal,summarise,mu=round(mean(Rho),ifelse(mean(Rho)>10,0,1)))
      stats$SDR=''
      stats$SDR[stats$Feature == 'proc' & stats$Extremal == 'min']='SPT'
      stats$SDR[stats$Feature == 'proc' & stats$Extremal == 'max']='LPT'
      stats$SDR[stats$Feature == 'jobWrm' & stats$Extremal == 'min']='LWR'
      stats$SDR[stats$Feature == 'jobWrm' & stats$Extremal == 'max']='MWR'
      stats$SDR <- factor(stats$SDR,levels=c(sdrs,''))

      stats$Feature <- factorFeature(stats$Feature,F)
      stats$Step=quantile(StepwiseOptimality$Stats$Step,0.25)

      p <- p +
        geom_text(data = stats, size=4, hjust=1,
                  aes(y=0.5, color=Extremal, vjust=as.numeric(Extremal)), label='rho', parse=T)+
        geom_text(data = stats, size=4, hjust=0,
                  aes(y=0.5, color=Extremal, vjust=as.numeric(Extremal), label=paste(paste0('=',mu,'%'),SDR)))
    }

  if(!is.na(save)){
    problem=ifelse(length(levels(StepwiseOptimality$Stats$Problem))>1,'ALL',as.character(StepwiseOptimality$Stats$Problem[1]))
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

  fname=paste(paste0(DataDir,'Stepwise/evolution'),problem,dim,'csv',sep='.')
  if(file.exists(fname)) {
    stat = read_csv(fname)
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

plot.StepwiseEvolution <- function(problem,dim,save=NA){

  stat = get.StepwiseFeatures(problem,dim)
  if(is.null(stat)) { return(NULL) }

  stat$Feature = factorFeature(stat$Feature,F)
  stat$FeatureType = factorFeatureType(stat$Feature)
  if(all(is.na(stat$mu))) { return(NULL) }

  p=ggplot(stat,aes(x=Step,color=Track,fill=Track))+
    geom_line(aes(y=mu),size=1)+
    facet_wrap(~Feature,ncol = 4, scales = 'free_y')+
    xlab('Step')+
    ggplotColor(name='Track',num=length(unique(stat$Track)))+
    axisStep(dim)+axisCompact

  txt=expression('Evolution of scaled feature ' * ~ tilde(bold(phi))[i])
  p=p+ylab(txt)

  if(!is.na(save)){
    fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'evolution',extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

stats.singleFeat <- function(CDR){
  stat <- rho.statistic(CDR,c('FeatureType','Feature','Extremal'))
  stat2 <- rho.statistic(CDR,c('FeatureType','Feature','Extremal'),rhoValue = 'RhoFortified')
  stat$Training.Fortified=stat2$Training.Rho
  stat$Diff <- stat$Training.Rho-stat$Training.Fortified
  stat$Test.Rho=NULL
  stat$NTest=NULL
  stat$Problem<-factorProblem(stat,F)
  stat <- arrange(stat, Training.Rho) # order w.r.t. lowest mean
  return(stat)
}
