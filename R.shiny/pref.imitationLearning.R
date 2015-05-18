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

getFileNamesIL <- function(problem,dim,CDR=T,rank='p',probability='equal',timedependent=F){
  times=ifelse(timedependent,'timedependent','timeindependent')
  files=list.files(paste0(DataDir,'PREF/CDR'),paste('(full|exhaust)',problem,dim,rank,'*',probability,'weights',times,sep='.'))
  files=files[grep('OPT|IL',files)]
  return(files)
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
  p <- pref.boxplot(CDR,NULL,'Supervision','Track','Imitation learning',F,ifelse(any(CDR$Extended),'Extended',NA))
  return(p)
}

plot.imitationLearning.weights <- function(problem,dim){
  file_list = getFileNamesIL(problem,dim)
  if(length(file_list)<=1) return(NULL)

  w <- do.call(rbind, lapply(file_list, function(X) { data.frame(Track = basename(X), subset(get.prefWeights(X,F),NrFeat==16)) } ))

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

