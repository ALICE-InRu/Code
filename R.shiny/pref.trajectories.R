get.trainingDataSize <- function(problems,dim,tracks='ALL'){
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
  stats$Track=factorTrack(stats$Track)
  return(stats)
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

get.preferenceSetSize <- function(problems,dim,tracks='ALL',ranks=c('a','b','f','p')){
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
  stats$Track=factorTrack(stats$Track)
  stats$Rank=factorRank(stats$Rank)
  return(stats)
}

plot.preferenceSetSize <- function(preferenceSetSize){
  preferenceSetSize$Rank=factorRank(preferenceSetSize$Rank,F)
  p=ggplot(preferenceSetSize, aes(x=Step,y=V1,color=Rank))+
    geom_line(size=1)+
    facet_grid(Problem~Track,scales='free_y')+
    ggplotColor('Ranking',num = 4)+
    ylab(expression('Size of preference set, |' * S * '|'))+
    axisStep(preferenceSetSize$Step)+axisCompact
  return(p)
}


getSingleCDR=function(logFile,NrFeat,Model,problem=NULL,dim=NULL,set='train'){

  if(grepl('.csv$',logFile)){logFile=substr(logFile,1,str_length(logFile)-4)}

  model.rex="(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9x]+).(?<Rank>[a-z]).(?<Track>[A-Z]{2}[A-Z0-9]+).(?<Probability>[a-z0-9]+).weights.time"
  m=regexpr(model.rex,logFile,perl=T)
  if(is.null(problem)){ problem = getAttribute(logFile,m,1) }
  if(is.null(dim)){ dim = getAttribute(logFile,m,2)}
  Rank=getAttribute(logFile,m,3)
  Track=getAttribute(logFile,m,4)
  Prob=getAttribute(logFile,m,5)

  fname=paste('../liblinear','CDR',logFile,paste(paste('F',NrFeat,sep=''),paste('Model',Model,sep=''),'on',problem,dim,set,'csv',sep='.'),sep='/')
  if(!file.exists(fname)){return(NULL)}
  dat=read.csv(fname)
  dat$Problem=problem
  dat$NrFeat=NrFeat
  dat$Model=Model
  dat$Prob=Prob
  dat$Rank=Rank
  dat$Track=Track

  return(dat)
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

get.rhoTracksRanks <- function(problems,dim,tracks=c(sdrs,'OPT','RND','ALL'),
                               ranks=c('a','b','f','p'),
                               timedependent=F,probability='equal'){
  if(length(problems)>1) problems=paste0('(',paste(problems,collapse='|'),')')
  if(length(tracks)>1) tracks=paste0('(',paste(tracks,collapse='|'),')')
  if(length(ranks)>1) ranks=paste0('(',paste(ranks,collapse='|'),')')

  files=list.files('../liblinear/CDR',paste('^full',problems,dim,ranks,tracks,probability,'weights',ifelse(timedependent,'timedependent','timeindependent'),sep='.'))

  CDR=NULL
  for(file in files){
    CDR=rbind(CDR,getSingleCDR(file,16,1,set = 'train'))
  }
  if(!is.null(CDR)){
    CDR$Track=factorTrack(CDR$Track)
    CDR$Rank=factorRank(CDR$Rank)
    CDR$Rho=factorRho(CDR)
    CDR$Dimension=factorDimension(CDR)
  }
  return(CDR)
}

joinRhoSDR <- function(rhoTracksRanks,SDR){
  rhoTracksRanks$Model='PREF'
  if(!is.null(SDR)){
    SDR=subset(SDR, Problem %in% rhoTracksRanks$Problem &
                 Dimension %in% rhoTracksRanks$Dimension & Set %in% rhoTracksRanks$Set)
    SDR$Rank=NA
    SDR$Track=SDR$SDR
    SDR$Model='SDR'
    cols=intersect(names(rhoTracksRanks),names(SDR))
    rhoTracksRanks=rbind(rhoTracksRanks[,cols],SDR[,cols])
  }
  return(rhoTracksRanks)
}

plot.rhoTracksRanks <- function(rhoTracksRanks,SDR=NULL){

  if(is.null(rhoTracksRanks)){ return(NULL) }
  #pref.boxplot(rhoTracksRanks,all.dataset.SDR,'Rank','Track',xText = 'Ranking')
  rhoTracksRanks=joinRhoSDR(rhoTracksRanks,SDR)
  rhoTracksRanks$Rank = factorRank(rhoTracksRanks$Rank,F)
  rhoTracksRanks$Track = factorTrack(rhoTracksRanks$Track)

  p <- ggplot(data=rhoTracksRanks , aes(y=Rho, x=Track , fill=Rank)) + geom_boxplot() +
    facet_grid(Problem ~ Track, scale='free')+
    xlab('') + ylab(rhoLabel) + axisCompactY +
    ggplotFill('Ranking',5)

  return(p)

}

table.rhoTracksRanks <- function(problem,rhoTracksRanks,SDR=NULL,save=NA){
  if(is.null(rhoTracksRanks)) return(NULL)
  rhoTracksRanks=subset(rhoTracksRanks,Problem==problem)
  rhoTracksRanks=joinRhoSDR(rhoTracksRanks,SDR)
  stat=ddply(rhoTracksRanks,~Problem+Model+Track+Rank+Set,function(x) summary(x$Rho))
  stat <- arrange(stat, Mean) # order w.r.t. lowest mean
  # table
  lbl<-paste0('stat.pref.',problem)
  tbl=xtable(stat,label=(lbl),caption=paste('Main statistics for',problem))
  if(is.na(save)) { return(tbl)
  } else {
    print(tbl,include.rownames = FALSE,file=paste(lbl,'.txt',sep=''))
  }
}
