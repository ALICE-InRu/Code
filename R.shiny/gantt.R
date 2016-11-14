get.raw <- function(problem,numJobs=6,numMacs=5,PID=0){
  dim <- paste(numJobs,numMacs,sep='x')
  dat <- read.csv(paste0('../../Data/Raw/',problem,'.',dim,'.train.txt'))
  dat <- dat[(5+PID*(numJobs+4)):(4+numJobs+PID*(numJobs+4)),]
  dat <- stringr::str_split(dat,' ')
  p <- matrix(NA,nrow = numJobs, ncol = numMacs)
  for(job in 1:numJobs){
    p[job,1:numMacs]=as.numeric(dat[[job]][seq(2,2*numMacs,by = 2)])
  }
  p <- as.data.frame(p)
  colnames(p)=paste0('M',1:numMacs)
  p$Job = factor(paste0('J',1:numJobs))
  p$Problem <- problem
  p$Dimension <- dim
  return(melt(p,c('Problem','Dimension','Job'), variable.name = 'Machine', value.name = 'Proc'))
}

plot.raw <- function(problems=c('f.rnd','f.rndn','f.jc','f.mc','f.mxc'), PID=0){
  dat <- do.call(rbind, lapply(problems, function(problem) {get.raw(problem,PID=PID)}))
  dat$Problem <- factorProblem(dat,F)
  ggplot(dat, aes(x=Machine,y=Proc,shape=Job))+geom_point()+xlab(NULL)+
    facet_wrap(~Problem+Dimension,scales='free',nrow=1)+ylab(expression(p[ja]))
}

get.gantt <- function(problem,dim,SDR='ALL',plotPID=-1,all.trdat=NULL){
  if(is.null(all.trdat)){
    trdat <- get.files.TRDAT(problem,dim,SDR)
  } else if (SDR!='ALL') {
    trdat=subset(all.trdat,Track==SDR)
  } else { trdat=all.trdat }

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

plot.gantt <- function(gantt,step,plotPhi=F,
                       plotStep=F,TightTime=F,xlabel='Time',ylabel='Machine',ncol=2,cmaxMargin=25,vchi=F){

  NumJobs=max(gantt$Job)
  NumMacs=max(gantt$Mac)

  gantt$factor = interaction(gantt$Problem,gantt$Dimension,gantt$Track,sep=', ')

  fdat <- subset(gantt,Followed==T & Step<step)
  pdat <- subset(gantt,Step==step)

  maxMakespan=ifelse(TightTime,max(pdat$phi.makespan),max(gantt$phi.makespan))+cmaxMargin

  if(vchi){ cat('vchi_',step,'=(',fdat$Job,')\n') }

  p=ggplot(fdat,aes(x=x,y=Mac))+
    ggplotFill('Job',NumJobs)+
    scale_y_continuous(ylabel, breaks=1:NumMacs, limits = c(0.25, NumMacs+0.5))+
    scale_x_continuous(xlabel, expand=c(0,0), limits = c(0, maxMakespan))+
    theme(legend.position="none")+facet_wrap(~factor,ncol=2)

  if(nrow(fdat)>0){
    cmax = ddply(fdat,~Problem+Dimension+Track,summarise,x=max(phi.endTime),Mac=0.4)
    p=p+geom_rect(aes(fill=as.factor(Job),
                      xmin=phi.startTime,xmax=phi.endTime,
                      ymin=Mac-0.4,ymax=Mac+0.4))+
      geom_text(size=4,aes(label=Job))+
      geom_vline(data = cmax, aes(xintercept=x), linetype='dotted')+
      geom_text(data = cmax, label='C[max]', parse=T, size=4, hjust=1, vjust=1)+
      geom_text(data = cmax, aes(label=x), size=4, hjust=0, vjust=1)
  }
  if(nrow(pdat)>0){
    overlapping=duplicated(pdat$Mac)
    if(any(overlapping)){
      for(mac in 1:NumMacs){
        for(track in unique(pdat$Track)){
          overlap = pdat$Mac==mac & pdat$Track==track
          if(sum(overlap)>1){
            pdat$Mac[overlap]=pdat$Mac[overlap]+seq(0.2,-0.2,length.out = sum(overlap))
          }
        }
      }
    }

    if(plotPhi){
      phi = ddply(pdat,~Problem+Dimension+Track+Job+Mac,summarise,
                  x=max(phi.endTime),phi.jobWrm=phi.jobWrm,phi.proc=phi.proc)

      p=p+
        geom_text(data = phi, aes(label='proc\njobWrm',y=Mac-0.2), size=3, hjust=1)+
        geom_text(data = phi, aes(label=paste(phi.proc,phi.jobWrm,sep='\n'),y=Mac-0.2), size=3, hjust=0)

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
                    alpha=0.2)+
        geom_text(data=pdat, size=4, aes(label=Job))
    }
  }

  if(plotStep){
    p <- p+annotate("text", x = 5, y=0.4, vjust=1, hjust=0, size=4,
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
