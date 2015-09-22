fixUnsupIL <- function(){
  for(dir in list.files('../../Data/PREF/CDR/','IL',full.names = T)){
    m=regexpr('full.(?<Problem>[j|f].[a-z]+).(?<Dimension>[0-9]+x[0-9]+).[a-z].IL(?<Iter>[0-9]+)',dir,perl=T)
    file=paste(dir,paste(getAttribute(dir,m,'Problem'),getAttribute(dir,m,'Dimension'),'train','csv',sep='.'),sep='/')
    dat=read_csv(file)
    iter=getAttribute(dir,m,'Iter',F)
    maxPID = ifelse(grepl('EXT',file),iter+1,1)*ifelse(getAttribute(dir,m,'Dimension')=='6x5',500,300)
    if(nrow(dat)>maxPID){
      print(paste('Limiting',file,'to',maxPID))
      dat=dat[1:maxPID,]
      write.csv(dat,file,row.names = F, quote = F)
    } else if (nrow(dat)<maxPID){
      print(paste(file,'is',nrow(dat),'which is less than',maxPID))
    }
  }
}

getFileNamesIL <- function(problems,dim,rank='p',bias='equal',timedependent=F){
  tracks=c('OPT','LOCOPT','ILSUP','ILUNSUP','ILFIXSUP')
  tracks=c(tracks,paste0(tracks,'EXT'))
  get.CDR.file_list(problems,dim,tracks,rank,timedependent,bias,lmax = F)
}

get.CDR.IL <- function(problems,dim){
  files = getFileNamesIL(problems,dim)
  if(length(files)<=1) return(NULL)
  return(get.CDR(files,16,1,c('train','test')))
}

stats.imitationLearning <- function(CDR){
  stat <- rho.statistic(CDR,c('Track','Extended','Supervision','Iter'))
  stat <- arrange(stat, Training.Rho, Test.Rho) # order w.r.t. lowest mean
  return(stat)
}

plot.imitationLearning.boxplot <- function(CDR){
  p <- pref.boxplot(CDR,NULL,'Supervision','Track',expression(beta[i]),F,ifelse(any(CDR$Extended),'Extended',NA))
  return(p)
}

plot.imitationLearning.weights <- function(problem,dim){
  file_list = getFileNamesIL(problem,dim)
  if(length(file_list)<=1) return(NULL)

  w <- do.call(rbind, lapply(file_list, function(X) {
    data.frame(Track = basename(X), subset(get.prefWeights(X),NrFeat==16)) } ))

  w$Track=getAttribute(w$Track,regexpr('(?<Track>[A-Z]{2}[A-Z0-9]+)',w$Track,perl=T),'Track')
  w=factorTrack(w)
  w$Feature = factorFeature(w$Feature,F)

  w=ddply(w,~Iter+Supervision+Extended,mutate,sc.value=Step.1/sqrt(sum(Step.1*Step.1)))

  wExtOpt=subset(w,Extended==T & Track=='OPT')
  wExt=subset(w,Extended==T & Track!='OPT')
  wOpt=subset(w,Track=='OPT' & Extended==F)
  w=subset(w,Iter>0 & Extended==F)

  for(supervision in unique(w$Supervision)){
    wOpt$Supervision=supervision
    w=rbind(w,wOpt)
  }

  if(!('Fixed' %in% unique(w$Supervision)) & nrow(wExtOpt)>0){
    wExtOpt$Supervision='Decreasing' }

  p=ggplot(w,aes(x=Iter,y=sc.value,color=Feature,group=Feature))+
    geom_line()+geom_point()+
    facet_grid(Supervision~Problem)+scale_size_manual(values=c(0.5,1.2))+
    xlab('iteration')+
    ylab(expression('Scaled weights for'*~phi))+
    scale_x_discrete(expand=c(0,-1))+
    guides(color = guide_legend(nrow = 4))+
    scale_color_discrete(expression('Feature'*~phi[i]*~''))+
    geom_point(data=wExtOpt,shape=2,size=4)

  if(nrow(wExt)>0){
    w=NULL
    for(supervision in wExt$Supervision){
      wOpt$Supervision=supervision
      wOpt$Extended=T
      w=rbind(w,wOpt,subset(wExt,Supervision==supervision))
    }
    p=p+geom_line(data=w,linetype='dotted')
  }

  return(p)
}

plot.passive.IL <- function(CDR.IL,height=0){
  CDR.OPT <- subset(CDR.IL, Iter==0)
  CDR.OPT$Type <- 'Passive Imitation Learning'
  p=plot.imitationLearning.boxplot(CDR.OPT)+guides(colour=FALSE)+
    facet_wrap(~Problem+Dimension+Set,ncol=3,scales='free_y')
  if(height>0){
    problem=ifelse(length(levels(CDR.OPT$Problem))>1,'ALL',as.character(CDR.OPT$Problem[1]))
    dim=ifelse(length(levels(CDR.OPT$Dimension))>1,'ALL',as.character(CDR.OPT$Dimension[1]))
    ggsave(paste(paste(subdir,problem,'boxplot',sep='/'),'passive',dim,'png',sep='.'),p,
           width = Width, height = height, units = units, dpi = dpi)
    # to get epsilon right: gm convert boxplot_passive_10x10.png boxplot_passive_10x10.pdf
  }
  return(p)
}
plot.active.IL <- function(CDR.IL,height=0){
  CDR.DA.EXT <- subset(CDR.IL, (Iter>0) | (Extended==0 & Track=='OPT'))
  CDR.DA.EXT$Type <- 'Active Imitation Learning'
  CDR.DA.EXT$Type <- paste(CDR.DA.EXT$Problem,CDR.DA.EXT$Dimension)
  levels(CDR.DA.EXT$Track)[1]='DA0'
  p=plot.imitationLearning.boxplot(CDR.DA.EXT)+facet_grid(Set~Type)+
    xlab(expression('iteration,' *~i))
  if(height>0){
    CDR.DA.EXT=droplevels(CDR.DA.EXT)
    problem=ifelse(length(levels(CDR.DA.EXT$Problem))>1,'ALL',as.character(CDR.DA.EXT$Problem[1]))
    dim=ifelse(length(levels(CDR.DA.EXT$Dimension))>1,'ALL',as.character(CDR.DA.EXT$Dimension[1]))
    fname=paste(paste(subdir,problem,'boxplot',sep='/'),'active',dim,extension,sep='.')
    print(fname)
    ggsave(fname,p,width = Width, height = height, units = units, dpi = dpi)
  }
  mu = ddply(subset(CDR.DA.EXT,Set=='train'),~Type+Extended+Iter+Supervision,summarise,Rho=mean(Rho))
  mu0 = mu[mu$Iter==0,]
  for(sup in setdiff(levels(mu$Supervision),'Fixed')){
    mu0$Supervision=sup
    for(ext in unique(mu$Extended[mu$Supervision==sup])){
      mu0$Extended=ext
      mu=rbind(mu,mu0)
    }
  }
  m <- ggplot(mu,aes(x=Iter,y=Rho,color=Supervision,linetype=Extended))+geom_line()+
    facet_wrap(~Type)+xlab(expression('iteration,' *~i))+ggplotColor('Supervision',3)+
    ylab(expression("Expected mean" * ~rho * ~" (%)"))+axisCompact
  print(m)
  return(p)
}

tmp <- function(problems,dim,iterT=7,save=NA){
  problem=problems[1]
  CDR.IL.10x10 <- get.CDR.IL(problem,'10x10')
  CDR.IL.6x5 <- get.CDR.IL(problems,'6x5')

  plot.passive.IL(CDR.IL.6x5,Height.third*2)
  plot.passive.IL(CDR.IL.10x10,Height.third)

  plot.active.IL(subset(CDR.IL.6x5,Problem %in% problems[1:1]),Height.half)
  plot.active.IL(subset(CDR.IL.10x10),Height.half)

  dim='10x10'
  CDR.IL <- subset(CDR.IL.10x10, (Supervision=='Unsupervised' & Extended==T) |
                     (Supervision!='Unsupervised' & Extended==F))
  CDR.IL$Type = 'Imitation Learning'

  source('pref.trajectories.R'); source('cmaes.R')
  CDR.compare <- get.CDRTracksRanksComparison(problem,dim,c('CMAESMINCMAX',ifelse(substring(problem,1,1)=='j','MWR','LWR')))
  CDR.compare$Supervision='Fixed'; CDR.compare$Iter=0;
  CDR.compare$Track=CDR.compare$SDR; CDR.compare$CDR=CDR.compare$SDR;
  CDR.compare$NrFeat=1; CDR.compare$Model=1; CDR.compare$Extended=F; CDR.compare$Bias=NA;
  CDR.compare$Type=ifelse(CDR.compare$SDR %in% sdrs,'SDR','CMA-ES')
  CDR.compare$Rank=NA; CDR.compare$SDR=NULL;

  CDR=rbind(CDR.IL,CDR.compare)
  CDR$Type <- factor(CDR$Type,levels=c('Imitation Learning','CMA-ES','SDR'))
  p=plot.imitationLearning.boxplot(CDR)
  p=p + facet_grid(Set~Type, scales='free',space = 'free')
  if(!is.na(save)){
    ggsave(paste0(paste(subdir,problem,'boxplot',sep='/'),'summary',dim,'png',sep='.'),
         width = Width, height = Height.half, units = units, dpi = dpi)
    # to get epsilon right: gm convert boxplot_summary_10x10.png boxplot_summary_10x10.pdf
  }
  stats.imitationLearning(CDR.IL)
  plot.imitationLearning.weights(problem,dimension)
}

