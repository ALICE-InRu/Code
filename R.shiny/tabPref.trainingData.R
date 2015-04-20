source('global.R')
source('liblinear.R')
problem='j.rnd'
rank='p'
dim='6x5'

plot.trainingDataSize <- function(problem,dim,rank){
  dat.raw <- getTrainingDataRaw(problem,dim,rank,'ALL',F)
  stats.raw=ddply(dat.raw,~Problem+Step+Track,function(X) nrow(X))
  #p=ggplot(stats.raw, aes(x=Step,y=V1,linetype=Track))
  p=ggplot(stats.raw, aes(x=Step,y=V1,color=Track))+
    ggplotColor('Track',num = length(levels(stats.raw$Track)))

  p=p+geom_line(size=1,position=position_jitter(w=0.25, h=0))+
    facet_wrap(~Problem,ncol=4)+
    ggplotCommon(stats.raw,ylabel = expression('Size of training set, |' * Phi * '|'))+
    theme(legend.justification=c(1,0), legend.position=c(1,-0.1))

  fname=paste(paste(subdir,'trdat',sep='/'),'size',dim,extension,sep='.')
  ggsave(fname,p,width=Width,height=Height.half,dpi=dpi,units=units)
}

plot.preferenceSetSize <- function(problems,dim){
  stats=NULL;
  ranks=c('b','f','p','a')
  for(problem in problems){
    for(rank in ranks){
      tmp <- getTrainingDataRaw(problem,dim,rank,'ALL',useDiff = T)
      tmp$Rank=rank
      tmp=ddply(tmp,~Problem+Step+Rank+Track,function(X) nrow(X))
      stats=rbind(stats,tmp)
    }
  }
  stats=formatData(stats)

  #stats$Rank <- factor(stats$Rank, levels=levels(stats$Rank), labels=paste0('S[',levels(stats$Rank),']'))

  p=ggplot(stats, aes(x=Step,y=V1,color=Track))+
    geom_line(size=1)+
    #facet_grid(Problem~Rank,scales='free_y',labeller = label_parsed)+
    facet_grid(.~Rank,scales='free_y',labeller = label_both)+
    ggplotColor('Track',num = length(levels(stats$Track)))+
    ggplotCommon(stats,ylabel = expression('Size of preference set, |' * S * '|'))

  fname=paste(paste(subdir,'prefdat',sep='/'),'size',dim,extension,sep='.')
  ggsave(fname,p,width=Width,height=Height.full,dpi=dpi,units=units)
}
