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
  #stats$Rank <- factor(stats$Rank, levels=levels(stats$Rank), labels=paste0('S[',levels(stats$Rank),']'))
  p=ggplot(preferenceSetSize, aes(x=Step,y=V1,color=Track))+
    geom_line(size=1)+
    #facet_grid(Problem~Rank,scales='free_y',labeller = label_parsed)+
    facet_grid(Problem~Rank,scales='free_y',labeller = label_both)+
    ggplotColor('Track',num = length(levels(preferenceSetSize$Track)))+
    ylab(expression('Size of preference set, |' * S * '|'))+
    axisStep(preferenceSetSize$Step)+axisCompact
  return(p)
}

