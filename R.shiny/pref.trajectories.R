get.trainingDataSize <- function(problems,dim,tracks){
  get.trainingDataSize1 <- function(problem){
    fname=paste('../trainingData/features/size','trainingSet',problem,dim,'csv',sep='.')
    if(file.exists(fname)){ stat=read.csv(fname)
    } else {
      trdat <- getTrainingDataRaw(problem,dim,tracks)
      stat=ddply(trdat,~Problem+Step+Track,function(X) nrow(X))
      write.csv(stat, file = fname, row.names = F, quote = F)
    }
    return(stat)
  }
  stats = NULL
  for(problem in problems){
    stats=rbind(stats,get.trainingDataSize1(problem))
  }

  return(formatData(stats))
}

plot.trainingDataSize <- function(trainingDataSize){
  p=ggplot(trainingDataSize, aes(x=Step,y=V1,color=Track))+
    ggplotColor('Track',num = length(levels(trainingDataSize$Track)))+
    geom_line(size=1,position=position_jitter(w=0.25, h=0))+
    facet_wrap(~Problem,ncol=2)+
    ylab(expression('Size of training set, |' * Phi * '|'))+
    axisStep(trainingDataSize$Step)+axisCompact
  return(p)
}

get.preferenceSetSize <- function(problems,dim,tracks,ranks){
  get.preferenceSetSize1 <- function(problem,rank){
    fname=paste('../trainingData/features/size','prefSet',problem,dim,rank,'csv',sep='.')
    if(file.exists(fname)){ stat=read.csv(fname)
    } else {
      stat <- getTrainingDataRaw(problem,dim,tracks,rank,useDiff = T)
      stat$Rank=rank
      stat=ddply(stat,~Problem+Step+Rank+Track,function(X) nrow(X))
      write.csv(stat, file = fname, row.names = F, quote = F)
    }
    return(stat)
  }
  stats = NULL
  for(problem in problems){
    for(rank in ranks){
      stats=rbind(stats,get.preferenceSetSize1(problem,rank))
    }
  }
  return(formatData(stats))
}

plot.preferenceSetSize <- function(preferenceSetSize){
  preferenceSetSize$Rank <- factor(preferenceSetSize$Rank,
                                   levels=c('p','f','b','a'),
                                   labels=c('partial subsequent','full subsequent','base','all'))
  p=ggplot(preferenceSetSize, aes(x=Step,y=V1,color=Rank))+
    geom_line(size=1)+
    facet_grid(Problem~Track,scales='free_y')+
    ggplotColor('Ranking',num = 4)+
    ylab(expression('Size of preference set, |' * S * '|'))+
    axisStep(preferenceSetSize$Step)+axisCompact
  return(p)
}

plot.preferenceSetBoxPlot <- function(problems,dim,tracks,ranks){

}

pref.boxplot <- function(CDR,SDR=NULL,ColorVar,xVar='CDRlbl',xText='CDR',tiltText=T,lineTypeVar=NA){

  colnames(CDR)[grep(ColorVar,colnames(CDR))]='ColorVar'
  colnames(CDR)[grep(xVar,colnames(CDR))]='xVar'

  if(!is.na(lineTypeVar))
    colnames(CDR)[grep(lineTypeVar,colnames(CDR))]='lineTypeVar'

  if(!is.null(SDR)){
    SDR <- subset(SDR,Dimension %in% CDR$Dimension & Problem %in% CDR$Problem)
    SDR$xVar=SDR$SDR
  }
  p=ggplot(CDR,aes(x=as.factor(xVar),y=Rho))

  if(!is.na(lineTypeVar))
    p=p+geom_boxplot(aes(color=ColorVar,linetype=lineTypeVar))+scale_linetype(lineTypeVar)
  else
    p=p+geom_boxplot(aes(color=ColorVar))

  if(!is.null(SDR)){ p=p+geom_boxplot(data=SDR,aes(fill=SDR))+ggplotFill('SDR',4);}
  p=p+facet_grid(Set~Problem,scale='free_x') +
    ggplotColor(xText,length(unique(CDR$ColorVar))) +
    xlab('')+ylab(rhoLabel)+
    axisCompactY+expand_limits(y = 0)

  if(tiltText){ p=p+theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) }
  return(p)
}

