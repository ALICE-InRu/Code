get.BestWorst <- function(problems,dim){

  allStat=NULL
  for(problem in problems){
    fname = paste('../trainingData/bw.summary',problem,dim,'csv',sep='.')
    if(file.exists(fname)){
      stat=read.csv(fname)
    } else {

      trdat=getTrainingDataRaw(problem,dim,'ALL',Global = T)
      if(!is.null(trdat)){

        trdat=formatData(trdat)

        trdat=ddply(trdat,~Track,transform,Followed=(Track!='OPT' & Followed==T) | (Track=='OPT' & Rho==0))

        split=ddply(trdat,~Problem+Dimension+Step+PID+Track+Followed,summarise,
                    best=min(Rho),
                    worst=max(Rho),
                    mu=mean(Rho),
                    .progress = "text")

        stat=ddply(split,~Problem+Track+Step+Followed,summarise,best.mu=mean(best),worst.mu=mean(worst),mu=mean(mu))
        write.csv(stat,fname,row.names=F,quote=F)
      } else {stat=NULL}
    }
    allStat=rbind(allStat,stat)
  }
  return(formatData(allStat))
}

plot.BestWorst <- function(problems,dim,track,save=NA){

  stat=get.BestWorst(problems,dim)
  if(is.null(stat)){return(NULL)}

  if(track=='OPT')
  {
    stat=subset(stat,Track=='OPT' & Followed==F)

    stat$Shop=factor(substr(stat$Problem,1,1),levels=c('j','f'),labels=c('JSP','FSP'))
    stat$Track=factor(stat$Track,levels='OPT',labels=('mean best and worst case scenario'))

    p = ggplot(stat, aes(x=Step))+
      ggplotColor(name='Problem',num=length(levels(stat$Problem)))+
      ggplotFill(name='Problem',num=length(levels(stat$Problem)))+
      facet_grid(Track~Shop)+
      axisStep(stat$Step)+axisCompact

    p=p+geom_ribbon(aes(ymin=best.mu,ymax=worst.mu,fill=Problem,color=Problem),alpha=0.2)
    p=p+geom_line(aes(y=mu,color=Problem),size=1,linetype='dashed')

  } else {

    p = ggplot(subset(stat,Followed==F), aes(x=Step))+
      ggplotColor(name='Trajectory',num=length(levels(stat$Track)))+
      ggplotFill(name='Trajectory',num=length(levels(stat$Track)))+
      facet_grid(Problem~.,scales= 'free_y')+
      axisStep(stat$Step)+axisCompact

    p=p+geom_ribbon(aes(ymin=best.mu,ymax=worst.mu,fill=Track,color=Track),alpha=0.5)
    p=p+geom_line(data=subset(stat,Followed==T),aes(y=best.mu,color=Track),size=1,linetype='dashed')
  }
  p=p+ylab(rhoLabel)

  if(!is.na(save)){
    problem=ifelse(length(problems)>1,'ALL',problems)
    fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'Track','casescenario',extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}
