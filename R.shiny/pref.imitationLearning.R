getSummaryFileNamesIL <- function(problem,dim,CDR=T,rank='p',probability='equal',timedependent=F){
  times=ifelse(timedependent,'timedependent','timeindependent')
  files=list.files('..//liblinear/CDR',paste('^summary.(full|exhaust)',problem,dim,rank,'*',probability,'weights',times,'csv',sep='.'))
  files=files[grep('OPT|IL',files)]
  return(files)
}

plot.imitationLearning.boxplot <- function(problem,dim){
  files = getSummaryFileNamesIL(problem,dim)
  if(length(files)==0) return(NULL)
  CDR=NULL;
  for (file in substr(files,9,100)){
    tmp=rbind(getSingleCDR(file,16,1,problem,dim,'train'),
              getSingleCDR(file,16,1,problem,dim,'test'))
    tmp$Extended=grepl('EXT',file)
    CDR=rbind(CDR,tmp)
  }
  dat=CDR
  CDR=formatData(CDR)
  p=pref.boxplot(CDR,NULL,'Supervision','Track','Imitation learning',F,ifelse(any(CDR$Extended),'Extended',NA))

  #CDR$CDR=interaction(CDR$Track,CDR$Iter,substr(CDR$Supervision,1,1))
  #  ks.train=ks.matrix(subset(CDR,Set=='train'),'Rho','CDR')
  #  ks.test=ks.matrix(subset(CDR,Set=='test'),'Rho','CDR')

  return(p)
}

plot.imitationLearning.weights <- function(problem,dim){
  files = getSummaryFileNamesIL(problem,dim)
  if(length(files)==0) return(NULL)
  w=NULL
  for (file in files){
    tmp=get.prefWeights(substr(file,9,100),F)
    tmp=subset(tmp,NrFeat==16)
    tmp$Track=file
    w=rbind(w,tmp)
  }
  m=regexpr('(?<Track>[A-Z]{2}[A-Z0-9]+)',w$Track,perl=T);
  w$Track=getAttribute(w$Track,m,1)
  w=formatData(w)
  w=ddply(w,~Iter+Supervision+Extended,mutate,sc.value=Step.1/sqrt(sum(Step.1*Step.1)))

  wExtOpt=subset(w,Extended==T & Track=='OPT')
  wExt=subset(w,Extended==T & Track!='OPT')
  wopt=subset(w,Track=='OPT' & Extended==F)
  w=subset(w,Iter>0 & Extended==F)

  for(supervision in unique(w$Supervision)){
    wopt$Supervision=supervision
    w=rbind(w,wopt)
  }
  if(!('Fixed' %in% unique(w$Supervision)) & nrow(wExtOpt)>0){
    wExtOpt$Supervision='Decreasing' }

  w$Problem=problem

  p=ggplot(w,aes(x=Iter,y=sc.value,color=Featurelbl,group=Feature))+
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
      wopt$Supervision=supervision
      wopt$Extended=T
      w=rbind(w,wopt,subset(wExt,Supervision==supervision))
    }
    p=p+geom_line(data=w,linetype='dotted')
  }

  return(p)
}

stats.imitationLearning <- function(problem,dim){
  files = getSummaryFileNamesIL(problem,dim)
  if(length(files)==0) return(NULL)
  stat=NULL;
  for (file in files){
    tmp=read.csv(paste('..//liblinear/CDR',file,sep='/'))
    tmp=subset(tmp,NrFeat==16 & Model==1)
    tmp$Track=file
    stat=rbind(stat,tmp)
  }

  m=regexpr('(?<Track>[A-Z]{2}[A-Z0-9]+)',stat$Track,perl=T);
  stat$Track=getAttribute(stat$Track,m,1)
  stat=formatData(stat)
  return(stat[order(stat$Iter,stat$Supervision),c(1,6:14)])
}
