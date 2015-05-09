get.gantt <- function(problem,dim,SDR='ALL',plotPID=-1){
  trdat <- get.files.TRDAT(problem,dim,SDR)
  if(plotPID>0){ trdat <- subset(trdat,PID==plotPID) }
  if(nrow(trdat)<1){return(NULL)}
  m=regexpr('(?<Job>[0-9]+).(?<Mac>[0-9]+).(?<StartTime>[0-9]+)',trdat$Dispatch,perl = T)
  trdat$Dimension=dim
  trdat$Step=trdat$Step-1 # start from 0
  trdat$Job=as.numeric(getAttribute(trdat$Dispatch,m,'Job'))+1
  trdat$phi.mac=trdat$phi.mac-min(trdat$phi.mac)+1
  trdat$x=trdat$phi.startTime+(trdat$phi.endTime-trdat$phi.startTime)/2
  return(trdat)
}

plot.gantt <- function(gantt,step){

  NumJobs=max(gantt$Job)
  NumMacs=max(gantt$phi.mac)
  maxMakespan=max(gantt$phi.makespan)+50 # margin to display Cmax notation

  fdat <- subset(gantt,Followed==T & Step<step)
  pdat <- subset(gantt,Step==step)
  p=ggplot(fdat,aes(x=x,y=phi.mac))+
    ggplotFill('Job',NumJobs)+
    scale_y_continuous('Machine', breaks=1:NumMacs)+
    scale_x_continuous('Time', expand=c(0,0), limits = c(0, maxMakespan))+
    theme(legend.position="none")+facet_wrap(~Problem+Dimension+Track,ncol=2)

  if(nrow(fdat)>0){
    cmax = ddply(fdat,~Problem+Dimension+Track,summarise,x=max(phi.endTime),phi.mac=0.3)
    p=p+geom_rect(aes(fill=as.factor(Job),
                      xmin=phi.startTime,xmax=phi.endTime,
                      ymin=phi.mac-0.4,ymax=phi.mac+0.4))+
      geom_text(size=4,aes(label=Job))+
      geom_vline(data = cmax, aes(xintercept=x), linetype='dotted')+
      geom_text(data = cmax, label='C[max]', parse=T, size=4, hjust=1, vjust=0)+
      geom_text(data = cmax, aes(label=x), size=4, hjust=0, vjust=0)
  }
  if(nrow(pdat)>0){
    p=p+geom_rect(data=pdat,
                  aes(fill=as.factor(Job),
                      xmin=phi.startTime,xmax=phi.endTime,
                      ymin=phi.mac-0.4,ymax=phi.mac+0.4),
                  linetype='dashed', color='black',
                  alpha=0.2, #aes(size=Rho),
                  position = position_jitter(w = 0, h = 0.1))+
      #scale_size(guide="none",range=c(1.5,1))+ # stronger line for lower rho
      geom_text(data=pdat, size=4, aes(label=Job), position=position_jitter(w = 0.1, h = 0.1))
    #p=p+ggtitle(paste('Step',step))
  } #else { p = p + ggtitle('Complete schedule') }

  return(p)
}

gif.gantt <- function(problem,dim,SDR='MWR',plotPID=10){
  gantt=get.gantt(proble,dim,SDR,plotPID)
  ## save images and convert them to a single GIF
  library(animation)
  saveGIF({
    for (step in 0:numericDimension(dim)) {
      print(plotStep(gantt,step))
    }
    print(plotStep(gantt,step+1))
  }, interval = 0.5, movie.name = paste(problem,dim,SDR,'gif',sep='.'), ani.width = 600, ani.height = 250, loop=F)

}
