plot.SDR <- function(SDR,type='boxplot',save=NA){

  SDR$Names=droplevels(factorSDR(SDR$SDR,F))
  p=ggplot(SDR,aes(fill=SDR,colour=Set))+
    ggplotColor("Data set",length(unique(SDR$Set)))+
    ggplotFill("Simple priority dispatching rule",4,levels(SDR$Names))+
    ylab(rhoLabel)+xlab('')+
    facet_wrap(ncol=2,~Problem+Dimension,scales='free_y')+
    guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
           colour = guide_legend(order=2, direction = "vertical", title.position = "top")
    )

  p=p+switch(type,
             'boxplot'=geom_boxplot(aes(x=SDR,y=Rho)),
             'density'=geom_density(aes(x=Rho),alpha=0.25))

  if(!is.na(save)){
    dir=paste(subdir,paste0(type,'Rho'),sep='/')
    dim=ifelse(length(levels(SDR$Dimension))>1,'ALL',SDR$Dimension[1])
    fname=paste(paste(dir,'SDR',dim,sep='.'),extension,sep='.')

    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

plot.BDR <- function(dim,problems,bdr.firstSDR,bdr.secSDR,bdr.split,save=NA){

  BDR=get.BDR(dim, problems, bdr.firstSDR, bdr.secSDR, bdr.split)
  if(is.null(BDR)) return()
  SDR=subset(dataset.SDR, (SDR==bdr.firstSDR|SDR==bdr.secSDR)
             & Dimension %in% BDR$Dimension & Problem %in% BDR$Problem & Set %in% BDR$Set)
  SDR$BDR=factorSDR(SDR$SDR,F)
  dat = rbind(SDR,BDR[,names(SDR)])

  p = ggplot(dat, aes(x=SDR,y=Rho,fill=SDR,color=Set))+geom_boxplot()+
    facet_wrap(~Problem+Dimension,ncol=2,scales='free_y')+
    ylab(rhoLabel)+xlab('')+
    guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
           colour = guide_legend(order=2, direction = "vertical", title.position = "top")
    )+
    ggplotColor('Data set',2)+
    ggplotFill('Dispatching rule',3, levels(dat$BDR))

  if(!is.na(save)){
    fname=paste(subdir,'boxplotRho.BDR.10x10','.',extension,sep='')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }

  return(p)
}

checkDifficulty <- function(dat){

  quartiles=ddply(dat,~Problem+Dimension, summarise, Q1 = round(quantile(Rho,.25),digits = 2), Q3 = round(quantile(Rho,.75), digits = 2))
  rownames(quartiles)=interaction(quartiles$Problem,quartiles$Dimension)

  dat=merge(dat,quartiles)
  split = ddply(dat,~Problem+Dimension+SDR, summarise, Easy = round(mean(Rho<=Q1)*100,digits = 2), Hard = round(mean(Rho>Q3)*100,digits = 2))

  Easy = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho<=Q1]),N=length(PID))
  Hard = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho>=Q3]),N=length(PID))

  return(list('Quartiles'=quartiles,'Split'=split,'Easy'=Easy,'Hard'=Hard))
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

get.BDR <- function(dim,problems,firstSDR='SPT',secSDR='MWR',split=40){
  files=list.files('../BDR',paste(paste(problems,collapse='|'),'*',firstSDR,secSDR,paste(split,'proc',sep=''),'csv',sep='.'))
  BDR <- get.files('../BDR/',files)
  BDR$SDR='BDR'
  BDR$BDR=paste(firstSDR,'(first',split,'%),',secSDR,'(last',100-split,'%)')
  BDR$Problem=factorProblem(BDR)
  BDR$Dimension=factorDimension(BDR)
  BDR$Rho=factorRho(BDR)
  BDR = subset(BDR,Dimension==dim & Problem %in% problems)
  if(nrow(BDR)>1) return(BDR)
  return(NULL)
}
