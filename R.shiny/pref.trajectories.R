get.trainingDataSize <- function(problems,dim,tracks='ALL'){
  get.trainingDataSize1 <- function(problem){
    fname=paste(paste0(DataDir,'Stepwise/size'),'trainingSet',problem,dim,'csv',sep='.')
    if(file.exists(fname)){ stat=read_csv(fname)
    } else {
      trdat <- get.files.TRDAT(problem,dim,tracks)
      if(is.null(trdat)) return(NULL)
      stat=ddply(trdat,~Problem+Step+Track,function(X) nrow(X))
      write.csv(stat, file = fname, row.names = F, quote = F)
    }
    return(stat)
  }
  stats = NULL
  for(problem in problems){
    stats=rbind(stats,get.trainingDataSize1(problem))
  }
  stats=factorTrack(stats)
  return(stats)
}

plot.trainingDataSize <- function(trainingDataSize){
  p=ggplot(trainingDataSize, aes(x=Step,y=V1,color=Track))+
    ggplotColor('Track',num = length(levels(trainingDataSize$Track)))+
    geom_line(size=1,position=position_jitter(w=0.25, h=0))+
    facet_wrap(~Problem,ncol=2)+
    ylab(expression('Size of training set, |' * Phi * '|'))+
    axisStep(trainingDataSize$Dimension[1])+axisCompact
  return(p)
}

get.preferenceSetSize <- function(problems,dim,tracks='ALL',ranks=c('a','b','f','p')){
  get.preferenceSetSize1 <- function(problem,rank){
    fname=paste(paste0(DataDir,'Stepwise/size'),'prefSet',problem,dim,rank,'csv',sep='.')
    if(file.exists(fname)){ stat=read_csv(fname)
    } else {
      stat <- get.files.TRDAT(problem,dim,tracks,rank,useDiff = T)
      if(is.null(stat)) { return(NULL) }
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
  stats=factorTrack(stats)
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
    axisStep(preferenceSetSize$Dimension[1])+axisCompact
  return(p)
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
  rhoTracksRanks = factorTrack(rhoTracksRanks)

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
