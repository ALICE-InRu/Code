plot.SDR <- function(dat,type='boxplot',save=NA){

  p=ggplot(dat,aes(fill=SDR,colour=Set))+
    ggplotColor("Data set",length(unique(dat$Set)))+
    ggplotFill("Simple priority dispatching rule",4,sdrNames)+
    ylab(rhoLabel)+
    facet_wrap(ncol=2,~Problem+Dimension,scales='free_y')+
    guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
           colour = guide_legend(order=2, direction = "vertical", title.position = "top")
    )

  p=p+switch(type,
             'boxplot'=geom_boxplot(aes(x=SDR,y=Rho)),
             'density'=geom_density(aes(x=Rho),alpha=0.25))

  dir=paste(subdir,paste0(type,'Rho'),sep='/')
  dimension=ifelse(length(levels(dat$Dimension))>1,'ALL',dat$Dimension[1])
  fname=paste(paste(dir,'SDR',dimension,sep='.'),extension,sep='.')

  if(save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  return(p)
}

plot.BDR <- function(dimension,problems,bdr.firstSDR,bdr.secSDR,bdr.split,save=NA){

  dat=fetchBDR(dimension, problems, bdr.firstSDR, bdr.secSDR, bdr.split)
  if(is.null(dat)) return()

  BDR=paste(bdr.firstSDR,'(first',bdr.split,'%),',bdr.secSDR,'(last',100-bdr.split,'%)')
  p = ggplot(dat, aes(x=SDR,y=Rho,fill=SDR,color=Set))+geom_boxplot()+
    facet_wrap(~Problem+Dimension,ncol=2,scales='free_y')+
    ylab(rhoLabel)+
    guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
           colour = guide_legend(order=2, direction = "vertical", title.position = "top")
    )+
    ggplotColor('Data set',1)+
    ggplotFill('Dispatching rule',3,c(BDR,sdrNames[grep(unique(dat$SDR)[2],sdrs)],sdrNames[grep(unique(dat$SDR)[3],sdrs)]))

  fname=paste(subdir,'boxplotRho.BDR.10x10','.',extension,sep='')
  if(save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

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

fetchBDR <- function(dim,problems,firstSDR,secSDR,split){
  fname=paste(paste(problems,collapse='|'),'*',firstSDR,secSDR,paste(split,'proc',sep=''),'csv',sep='.')
  BDR <- getfiles('../BDR/',pattern=fname)
  BDR$SDR='BDR'
  DAT = rbind(BDR,subset(all.dataset.SDR,SDR==firstSDR|SDR==secSDR))
  dat = subset(DAT,Dimension==dim & Problem %in% problems & Set=='train')
  if(nrow(subset(dat,SDR=='BDR'))==0) return(NULL)
  return(dat)
}
