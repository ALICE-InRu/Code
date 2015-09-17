plot.SDR <- function(SDR,type='boxplot',save=NA){

  SDR$Problem=factorProblem(SDR,F)
  SDR$Names=droplevels(factorSDR(SDR$SDR,F))
  p=ggplot(SDR,aes(fill=SDR,colour=Set))+
    ggplotColor("Data set",length(unique(SDR$Set)))+
    ggplotFill("Simple dispatching rule",length(sdrs),levels(SDR$Names))+
    xlab(NULL)+
    facet_wrap(ncol=2,~Problem+Dimension,scales='free_y')

  p=p+switch(type,
             'boxplot'=geom_boxplot(aes(x=SDR,y=Rho)),
             'density'=geom_density(aes(x=Rho),alpha=0.25))

  p <- p + themeBoxplot + cornerLegend(length(levels(droplevels(SDR$Problem))))

  if(!is.na(save)){
    dir=paste(subdir,paste0(type,'Rho'),sep='/')
    dim=ifelse(length(levels(droplevels(SDR$Dimension)))>1,'ALL',as.character(SDR$Dimension[1]))
    fname=paste(paste(dir,'SDR',dim,sep='.'),extension,sep='.')

    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

get.BDR <- function(dim,problems,bdr.firstSDR,bdr.secSDR,bdr.splits,fancyFactor=T){
  get.BDR1 <- function(split=40){
    files=list.files(paste0(DataDir,'BDR'),paste(paste0('(',paste(problems,collapse='|'),')'),dim,'(train|test)','csv',sep='.'))
    BDR <- get.files(paste0(DataDir,'BDR'),files)
    BDR = factorFromName(BDR)
    BDR$SDR='BDR'
    BDR <- subset(BDR, BDR == interaction(bdr.firstSDR,bdr.secSDR,split))
    if(nrow(BDR)<1) return(NULL)
    BDR$BDR.lbl=paste(bdr.firstSDR,'(first',split,'%),',bdr.secSDR,'(last',100-split,'%)')
    BDR$BDR=interaction(bdr.firstSDR,bdr.secSDR,split)
    BDR$Rho=factorRho(BDR)
    BDR = subset(BDR,!is.na(Rho))
    if(nrow(BDR)>1) return(BDR)
    return(NULL)
  }
  BDR=do.call(rbind, lapply(bdr.splits, get.BDR1 ))
}

plot.BDR <- function(dim,problem,bdr.firstSDR,bdr.secSDR,bdr.splits,save=NA,withRND=F,BDR=NULL){

  if(is.null(BDR)){
    BDR <- get.BDR(dim,problem,bdr.firstSDR,bdr.secSDR,bdr.splits)
  } else {
    BDR = subset(BDR,BDR %in% paste(bdr.firstSDR,bdr.secSDR,bdr.splits,sep='.'))
  }

  if(is.null(BDR)) return()
  baseline = c(bdr.firstSDR,bdr.secSDR)
  if(withRND) {baseline=c(baseline,'RND') }
  SDR=subset(dataset.SDR, (SDR %in% baseline)
             & Dimension %in% BDR$Dimension & Problem %in% BDR$Problem & Set %in% BDR$Set)
  SDR$BDR=factorSDR(SDR$SDR)
  SDR$BDR.lbl=factorSDR(SDR$SDR,F)
  dat = rbind(SDR,BDR[,names(SDR)])
  dat <- subset(dat, PID <= 500)
  dat <- droplevels(dat)

  mdat <- ddply(dat,~Problem+Dimension+BDR+SDR,function(x) summary(x$Rho))
  if(mdat[grep(bdr.firstSDR,mdat$SDR),'Mean']<mdat[grep(bdr.secSDR,mdat$SDR),'Mean']){
    lvs = c(bdr.firstSDR,'BDR',bdr.secSDR)
  } else {
    lvs = c(bdr.secSDR,'BDR',bdr.firstSDR)
  }
  dat$SDR <- factor(dat$SDR, levels=lvs)

  p = ggplot(dat, aes(x=SDR,y=Rho,fill=BDR.lbl,color=Set))+geom_boxplot()+
    facet_wrap(~Problem+Dimension,ncol=2,scales='free_y')+
    ggplotColor('Data set',2)+themeBoxplot+
    ggplotFill('Dispatching rule',3+length(bdr.splits), levels(dat$BDR.lbl))+
    themeVerticalLegend + guides(color=guide_legend(nrow=1))

  if(!is.na(save)){
    fname=paste0(subdir,paste('boxplotRho.BDR',dim,extension,sep='.'))
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}


gif.BDR <- function(problem='j.rnd',dim='10x10',bdr.firstSDR='SPT',bdr.secSDR='MWR'){
  ## save images and convert them to a single GIF

  bdr.splits=c(seq(0,numericDimension(dim),5))
  BDR <- get.BDR(dim,problem,bdr.firstSDR,bdr.secSDR,bdr.splits)
  ymax = max(BDR$Rho)

  #function to iterate over all splits
  BDR.animate <- function(splits) {
    lapply(splits, function(split) {
      BDR1 <- subset(BDR,BDR==paste(bdr.firstSDR,bdr.secSDR,split,sep='.'))
      p<-plot.BDR(dim,problem,bdr.firstSDR,bdr.secSDR,split,BDR=BDR1)
      p<-p+expand_limits(y = ymax)
      print(p)
    })
  }

  #save all iterations into one GIF
  library(animation)
  #ani.options(loop = FALSE) # doesn't seem to work!

  saveGIF(BDR.animate(bdr.splits), movie.name='animate.gif', ani.width = 600, ani.height = 250, nmax=length(bdr.splits))
  file.copy(from = 'animate.gif', to = paste(subdir,paste('animate',problem,dim,'BDR','gif',sep='.'),sep='/'))
  file.remove('animate.gif')
}


get.quartiles <- function(dat){
  quartiles=ddply(dat,~Problem+Dimension, summarise, Q1 = round(quantile(Rho,.25),digits = 2), Q3 = round(quantile(Rho,.75), digits = 2))
  rownames(quartiles)=interaction(quartiles$Problem,quartiles$Dimension)
  return(quartiles)
}

checkDifficulty <- function(dat, quartiles){

  dat=merge(dat,quartiles)

  split = ddply(dat,~Problem+Dimension+SDR, summarise, Easy = round(mean(Rho<=Q1)*100,digits = 2), Hard = round(mean(Rho>Q3)*100,digits = 2))

  Easy = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho<=Q1]),N=length(PID))
  Hard = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho>=Q3]),N=length(PID))

  return(list('Quartiles'=quartiles,'Split'=split,'Easy'=Easy,'Hard'=Hard))
}

labelDifficulty <- function(dat,quartiles){
  dat=merge(dat,quartiles)
  dat = ddply(dat,~Problem+Dimension,mutate,Difficulty=ifelse(Rho<=Q1,'Easy',ifelse(Rho>=Q3,'Hard','Medium')))
  dat$Difficulty <- factor(dat$Difficulty, levels=c('Easy','Medium','Hard'))
  dat$Q1=NULL
  dat$Q3=NULL
  return(dat)
}

splitSDR <- function(dat,problem,dim){
  sdrs=unique(dat$SDR)
  N=length(sdrs)

  if(nrow(dat)==0){return(NULL)}
  m=matrix(nrow = N, ncol = N);
  colnames(m)=sdrs; rownames(m)=sdrs
  for(i in 1:N){
    iPID=subset(dat,SDR==sdrs[i])$PIDs[[1]]
    for(j in 1:N){
      jPID=subset(dat,SDR==sdrs[j])$PIDs[[1]]
      m[i,j]=round(length(intersect(jPID,iPID))/dat$N[i]*100,digits = 2)
    }
  }
  return(as.data.frame(m))
}
