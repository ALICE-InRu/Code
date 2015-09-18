get.BestWorst <- function(problems,dim){
  stats=NULL
  for(problem in problems){
    fname = paste(paste0(DataDir,'Stepwise/bw'),problem,dim,'csv',sep='.')
    if(file.exists(fname)){
      stat=read_csv(fname)
    } else {
      trdat=get.files.TRDAT(problem,dim,'ALL')
      if(!is.null(trdat)){
        trdat=ddply(trdat,~Track,transform,Followed=(Track!='OPT' & Followed==T) | (Track=='OPT' & Rho==0))
        split=ddply(trdat,~Problem+Step+PID+Track+Followed,summarise,
                    best=min(Rho),
                    worst=max(Rho),
                    mu=mean(Rho),
                    .progress = "text")

        stat=ddply(split,~Problem+Track+Step+Followed,summarise,best.mu=mean(best),worst.mu=mean(worst),mu=mean(mu))
        write.csv(stat,fname,row.names=F,quote=F)
      } else {stat=NULL}
    }
    stats=rbind(stats,stat)
  }
  if(!is.null(stats)){ stats$Problem=factorProblem(stats) }

  return(stats)
}

plot.BestWorst <- function(problems,dim,tracks,save=NA,stat=NULL){
  if(is.null(tracks)){ tracks='ALL' }

  if(is.null(stat)){ stat=get.BestWorst(problems,dim) }
  if(!any(grepl('ALL',tracks))){
    stat <- subset(stat,Track %in% tracks)
  }

  stat$Problem <- factorProblem(stat,F)
  if(is.null(stat)){return(NULL)}

  if(length(tracks)==1 & tracks[1]=='OPT')
  {
    track='OPT'
    stat=subset(stat,Track=='OPT' & Followed==F)

    stat$Shop=factor(substr(stat$Problem,1,1),levels=c('j','f'),labels=c('JSP','FSP'))
    stat$Track=factor(stat$Track,levels='OPT',labels=('mean best and worst case scenario'))

    p = ggplot(stat, aes(x=Step))+
      ggplotColor(name='Problem',num=length(levels(stat$Problem)))+
      ggplotFill(name='Problem',num=length(levels(stat$Problem)))+
      facet_grid(Track~Shop)+
      axisStep(dim)+axisCompact

    p=p+geom_ribbon(aes(ymin=best.mu,ymax=worst.mu,fill=Problem,color=Problem),alpha=0.2)
    p=p+geom_line(aes(y=mu,color=Problem),size=1,linetype='dashed')

  } else {
    track='ALL'
    stat=factorTrack(stat)

    p = ggplot(subset(stat,Followed==F), aes(x=Step))+
      ggplotColor(name=expression(pi*~' '),num=length(levels(stat$Track)))+
      ggplotFill(name=expression(pi*~' '),num=length(levels(stat$Track)))+
      facet_wrap(~Problem,ncol=3,scales= 'free_y')+
      axisStep(dim)+axisCompact

    p=p+geom_ribbon(aes(ymin=best.mu,ymax=worst.mu,fill=Track,color=Track),alpha=0.5)
    p=p+geom_line(data=subset(stat,Followed==T),aes(y=best.mu,color=Track),size=1,linetype='dashed')
  }
  p=p+ylab(rhoLabel)

  if(!is.na(save)){
    problem=ifelse(length(problems)>1,'ALL',problems)
    fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,track,'casescenario',extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}


bw.spread <- function(problem,dim,variable='best.mu',orderTrack=F){
  bw <- get.BestWorst(problem,dim)
  if(is.null(bw)) return(NULL)
  bw$Problem <- factorProblem(bw,F)
  bw$Followed <- factor(bw$Followed, levels=c(F,T), labels=c('false','true'))
  colnames(bw)[grepl(variable,colnames(bw))]='variable'
  bw=bw[,grep('mu',colnames(bw),invert = T)]
  bw=tidyr::spread(bw,Followed,variable)
  bw=ddply(bw,~Problem+Track,summarise,
           TotalSpread=sum(true-false,na.rm = T),
           MeanSpread=mean(true-false,na.rm = T))

  bw=factorTrack(bw); bw$Extended=NULL
  tracks=setdiff(levels(bw$Track),'OPT')
  if(length(tracks)==0) return(NULL)
  tracks[grep('ES.rho',tracks)]='CMAESMINRHO'
  tracks[grep('ES.Cmax',tracks)]='CMAESMINCMAX'
  CDR.full <- get.many.CDR(get.CDR.file_list(problem,dim,tracks,'p',F),'train')
  CDR.full <- ddply(CDR.full,~Problem+Track,summarise,Rho=mean(Rho))
  CDR.compare <- subset(get.CDRTracksRanksComparison(problem,dim,tracks),Set=='train')
  CDR.compare <- ddply(CDR.compare,~Problem+SDR,summarise,Rho=mean(Rho))
  colnames(CDR.compare)[2]='Track'
  CDR <- merge(CDR.full,CDR.compare,by=c('Problem','Track'),type='inner',suffixes = c('Track','SDR'))
  CDR$TrackBoost <- CDR$RhoSDR-CDR$RhoTrack
  bw=merge(bw,CDR[,c('Problem','Track','TrackBoost')])

  if(orderTrack){
    bw$TotalSpread = bw$Track[order(bw$TotalSpread,decreasing = T)]
    bw$MeanSpread = bw$Track[order(bw$MeanSpread,decreasing = T)]
    bw$TrackBoost = bw$Track[order(bw$TrackBoost,decreasing = T)]
    bw$Track=NULL
  }

  return(bw)
}
