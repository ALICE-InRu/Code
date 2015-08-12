get.gantt <- function(problem,dim,SDR='ALL',plotPID=-1){
  trdat <- get.files.TRDAT(problem,dim,SDR)
  if(plotPID>0){ trdat <- subset(trdat,PID==plotPID) }
  if(nrow(trdat)<1){return(NULL)}
  m=regexpr('(?<Job>[0-9]+).(?<Mac>[0-9]+).(?<StartTime>[0-9]+)',trdat$Dispatch,perl = T)
  trdat$Dimension=dim
  trdat$Step=trdat$Step-1 # start from 0
  trdat$Job=as.numeric(getAttribute(trdat$Dispatch,m,'Job'))+1
  trdat$Mac=as.numeric(getAttribute(trdat$Dispatch,m,'Mac'))+1
  trdat$x=trdat$phi.startTime+(trdat$phi.endTime-trdat$phi.startTime)/2
  return(trdat)
}

plot.gantt <- function(gantt,step,plotPhi=F,plotStep=F){

  NumJobs=max(gantt$Job)
  NumMacs=max(gantt$Mac)
  maxMakespan=max(gantt$phi.makespan)+50 # margin to display Cmax notation

  fdat <- subset(gantt,Followed==T & Step<step)
  cat('vchi_',step,'=(',fdat$Job,')\n')
  pdat <- subset(gantt,Step==step)
  p=ggplot(fdat,aes(x=x,y=Mac))+
    ggplotFill('Job',NumJobs)+
    scale_y_continuous('Machine', breaks=1:NumMacs, limits = c(0.25, NumMacs+0.5))+
    scale_x_continuous('Time', expand=c(0,0), limits = c(0, maxMakespan))+
    theme(legend.position="none")+facet_wrap(~Problem+Dimension+Track,ncol=2)

  if(nrow(fdat)>0){
    cmax = ddply(fdat,~Problem+Dimension+Track,summarise,x=max(phi.endTime),Mac=0.3)
    p=p+geom_rect(aes(fill=as.factor(Job),
                      xmin=phi.startTime,xmax=phi.endTime,
                      ymin=Mac-0.4,ymax=Mac+0.4))+
      geom_text(size=4,aes(label=Job))+
      geom_vline(data = cmax, aes(xintercept=x), linetype='dotted')+
      geom_text(data = cmax, label='C[max]', parse=T, size=4, hjust=1, vjust=0)+
      geom_text(data = cmax, aes(label=x), size=4, hjust=0, vjust=0)
  }
  if(nrow(pdat)>0){

    if(plotPhi){
      phi = ddply(pdat,~Problem+Dimension+Track+Job+Mac,summarise,
                  x=max(phi.endTime),phi.jobWrm=phi.jobWrm,phi.proc=phi.proc)

      p=p+
        geom_text(data = phi, aes(label='proc',y=Mac-0.2), size=3, hjust=1)+
        geom_text(data = phi, aes(label=phi.proc,y=Mac-0.2), size=3, hjust=0)+
        geom_text(data = phi, aes(label='jobWrm',y=Mac+0.2), size=3, hjust=1)+
        geom_text(data = phi, aes(label=phi.jobWrm,y=Mac+0.2), size=3, hjust=0)

      ndat=subset(pdat,Followed==T)
      p <- p+geom_rect(data=ndat,
                aes(fill=as.factor(Job),
                    xmin=phi.startTime,xmax=phi.endTime,
                    ymin=Mac-0.4,ymax=Mac+0.4),
                linetype='dashed', color='black',
                alpha=0.2, size=1)+
        geom_text(data=ndat, size=4, aes(label=Job))

      pdat <- subset(pdat,Followed==F)
    }
    if(nrow(pdat)>0){
      p=p+geom_rect(data=pdat,
                    aes(fill=as.factor(Job),
                        xmin=phi.startTime,xmax=phi.endTime,
                        ymin=Mac-0.4,ymax=Mac+0.4),
                    linetype='dashed', color='black',
                    alpha=0.2, #aes(size=Rho),
                    position = position_jitter(w = 0, h = 0.1))+
        #scale_size(guide="none",range=c(1.5,1))+ # stronger line for lower rho
        geom_text(data=pdat, size=4, aes(label=Job), position=position_jitter(w = 0.1, h = 0.1))
    }
  }

  if(plotStep){
    p <- p+annotate("text", x = 5, y = 0.3, vjust=1, hjust=0, size=4,
                    label = ifelse(nrow(pdat)>0,paste0("k=",step),'complete schedule'))
  }

  return(p)
}

gif.gantt <- function(problem,dim,SDR='MWR',plotPID=1){
  gantt=get.gantt(problem,dim,SDR,plotPID)
  ## save images and convert them to a single GIF

  #function to iterate over all dispatches
  gantt.animate <- function(steps) {
    lapply(steps, function(step) { print(plot.gantt(gantt,step,F,T))
    })
  }

  #save all iterations into one GIF
  library(animation)
  #ani.options(loop = FALSE) # doesn't seem to work!

  steps=c(seq(0,numericDimension(dim),1),
          rep(numericDimension(dim),numericDimension(dim)))

  saveGIF(gantt.animate(steps), movie.name='animate.gif', ani.width = 600, ani.height = 250, nmax=length(steps))
  file.copy(from = 'animate.gif', to = paste(subdir,paste('animate',problem,dim,SDR,'gif',sep='.'),sep='/'))
  file.remove('animate.gif')
}
