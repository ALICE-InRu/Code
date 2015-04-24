library('LiblineaR')

stepwiseProbability <- function(STEP,problem,dimension,probability){
  dim=max(STEP)
  half=round(dim/2,digit=0)
  last=dim-half
  w=switch(probability,
           'linear'=1:max(STEP),
           'opt'=1-stat.StepwiseOptimality(problem,dimension)$Stats$rnd.mu,
           'bcs'=subset(stat.BestWorst(problem,dimension),Track=='OPT' & Followed==F)$best.mu,
           'wcs'=subset(stat.BestWorst(problem,dimension),Track=='OPT' & Followed==F)$worst.mu,
           'dbl1st'=c(rep(2,half),rep(1,last)),
           'dbl2nd'=c(rep(1,half),rep(2,last)),
           rep(1,max(STEP)))
  w=w/sum(w); # normalize
  return(w[STEP])
}

estimate.prefModels <- function(problem,dimension,start,probability,timedependent,tracks,rank){
  ix=grepl('IL',tracks)
  if(any(ix)){ tracks[ix]=paste0(substr(tracks[ix],1,2),'[0-9]+',substr(tracks[ix],3,100)) }
  tracks=paste0('(',paste(tracks,collapse = '|'),')')
  m=list.files('../liblinear/CDR/',
               paste(paste0('^',start),problem,dimension,rank,tracks,probability,"weights",ifelse(timedependent,'timedependent','timeindependent'),sep='.'))
  minNum=ifelse(start=='full',2,697)
  for(model in m){ rho.statistic(model,minNum = minNum) }
  return(paste('Estimate LIBLINEAR models for',length(m),'files'))
}

rho.statistic <- function(model,minNum=697){
  #choose(16,1)+choose(16,2)+choose(16,3)+choose(16,16)==697

  fname=paste('../liblinear/CDR/summary',model,sep='.')
  if(!grepl('.csv',fname)){ fname=paste(fname,'csv',sep='.')}

  if(file.exists(fname)){ rho.stats=read.csv(fname)}
  else{
    files=list.files(paste('..//liblinear/CDR',model,sep='/'))
    print(paste(length(files),'models found for',model))
    if(length(files)<minNum){return(NULL)}

    model.rex="(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9x]+).(?<Rank>[a-z]).(?<Track>[A-Z]{2}[A-Z0-9]+).(?<Probability>[a-z0-9]+).weights.time"
    m=regexpr(model.rex,model,perl=T)
    problem=getAttribute(model,m,1)
    rank=getAttribute(model,m,3)
    track=getAttribute(model,m,4)
    probability=getAttribute(model,m,5)
    timeindependent=grepl('timeindependent$',model)
    print(paste(rank,track,probability,timeindependent))

    ALLDAT=NULL
    name.rex="F(?<NrFeat>[0-9]+).Model(?<Model>[0-9]+)"
    for(file in files){
      dat=read.csv(paste('..//liblinear/CDR',model,file,sep='/'))
      m=regexpr(name.rex,file,perl=T)
      dat$NrFeat <- as.factor(getAttribute(file,m,1))
      dat$Model <- as.factor(getAttribute(file,m,2))
      dat$Heuristic=NULL
      dat$Prob=probability
      ALLDAT=rbind(ALLDAT,dat)
    }
    ALLDAT$Problem=problem
    ALLDAT$TimeIndependent=timeindependent
    dat=formatData(ALLDAT);
    Ntrain=quantile(unique(subset(dat,Set=='train')$PID),.8) # 80% of training data saved for validation
    levels(dat$Set)=c(levels(dat$Set),'validation')
    dat$Set[dat$Set=='train' & dat$PID>Ntrain]='validation' # 20% of training data saved for validation

    rho.stats = ddply(dat,~Problem+NrFeat+Model+Prob+TimeIndependent, summarise,
                      Training.Rho = round(mean(Rho[Set=='train']), digits = 5),
                      NTrain = sum(Set=='train'),
                      Validation.Rho = round(mean(Rho[Set=='validation']), digits = 5),
                      NValidation = sum(Set=='validation'),
                      Test.Rho = round(mean(Rho[Set=='test']), digits = 5),
                      NTest = sum(Set=='test'))

    write.table(rho.stats, file=fname, quote=F,row.names=F,dec='.',sep=',')
  }
  return(rho.stats)
}

plot.trainingDataSize <- function(problem,dim,track,save=NA){
  trdat <- getTrainingDataRaw(problem,dim,track)

  stats.raw=ddply(trdat,~Problem+Step+Track,function(X) nrow(X))
  stats.raw=formatData(stats.raw)

  #p=ggplot(stats.raw, aes(x=Step,y=V1,linetype=Track))
  p=ggplot(stats.raw, aes(x=Step,y=V1,color=Track))+
    ggplotColor('Track',num = length(levels(stats.raw$Track)))

  p=p+geom_line(size=1,position=position_jitter(w=0.25, h=0))+
    facet_wrap(~Problem,ncol=4)+
    ylab(expression('Size of training set, |' * Phi * '|'))+
    axisStep(stats.raw$Step)+axisCompact

  if(!is.na(save)){
    fname=paste(paste(subdir,'trdat',sep='/'),'size',dim,extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }
  return(p)

}

plot.preferenceSetSize <- function(problems,dim,track,ranks,save=NA){
  stats=NULL;
  for(problem in problems){
    for(rank in ranks){
      tmp <- getTrainingDataRaw(problem,dim,track,rank,useDiff = T)
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
    ylab(expression('Size of preference set, |' * S * '|'))+
    axisStep(stats$Step)+axisCompact

  if(!is.na(save)){
    fname=paste(paste(subdir,'prefdat',sep='/'),'size',dim,extension,sep='.')
    if(save=='full')
      ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
    else if(save=='half')
      ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  }
  return(p)

}

