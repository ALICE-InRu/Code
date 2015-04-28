get.files <- function(dir, files, addFileNameColumn=F){
  dat=NULL
  print(files)
  for(file in files){
    tmp=read.csv(paste(dir,file,sep='/'))
    if(addFileNameColumn) {tmp$File=file}
    dat=rbind(dat,tmp)
  }
  return(dat)
}

get.files.OPT <- function(){
  opt=get.files('../OPT', list.files('../OPT'))
  colnames(opt)[grep('Makespan',colnames(opt))]='Optimum'
  opt=subset(opt,Solved=='opt')
  opt$Problem = factorProblem(opt)
  opt$Dimension = factorDimension(opt)
  opt$Set=factorSet(opt$Set)
  return(opt[,names(opt) %in%
               c('Name','Problem','Dimension','PID','Set','Optimum') ])
}

get.files.SDR <- function(){
  sdr=get.files('../SDR', list.files('../SDR'))
  sdr$Problem = factorProblem(sdr)
  sdr$Dimension = factorDimension(sdr)
  sdr$SDR=factorSDR(sdr$SDR)
  sdr$Rho=factorRho(sdr)
  sdr$Set=factorSet(sdr$Set)
  sdr=subset(sdr,!is.na(Rho))
  return(sdr[,names(sdr) %in%
             c('Name','Problem','Dimension','PID','Set','Makespan','Rho','SDR') ])
}

Ntrain10x10=300
Ntrain6x5=500

get.files.TRDAT <- function(problems,dim,tracks,rank='p',useDiff=F,Global=F){
  fileEnd = ifelse(useDiff,paste0('.diff.',rank),'')
  fileEnd = paste0(ifelse(Global,'Global','Local'),fileEnd,'.csv')

  ix = tracks=='ALL'
  if(any(ix)){ tracks=c(tracks[-ix],paste(c('OPT','RND',sdrs))) }
  ix=substr(tracks,1,2)=='IL'
  if(any(ix)){
    m=regexpr('IL(?<iter>[0-9]+)(?<track>[A-Z]+)',tracks[ix],perl=T)
    iter=getAttribute(tracks[ix],m,1)
    super=getAttribute(tracks[ix],m,2)
    tracks=c('OPT',tracks[-ix],paste0('IL',1:iter,super))
  }
  tracks=unique(tracks)

  trdat=NULL
  for(problem in problems){
    for(track in tracks){
      file=list.files('../trainingData/', paste('^trdat',problem,dim,track,fileEnd,sep='.'),
                      full.names = T)
      if(length(file)>0){
        dat=read.csv(file)
        ix=grep('phi',names(dat))
        names(dat)[ix]=factorFeature(names(dat)[ix],phis = T)
        dat=dat[,grep('PID|Dispatch|Step|phi|Followed|ResultingOptMakespan',names(dat))]
        dat$Problem=problem
        dat$Track=track
        trdat=rbind(trdat,dat)
      } else { print(paste('training file for',problem,track,'does not exist')) }
    }
  }
  if(is.null(trdat)){return(NULL)}
  if(min(trdat$Step)==0) {trdat$Step=trdat$Step+1}
  trdat$Name=interaction(trdat$Problem,dim,'train',trdat$PID)
  trdat$Rho=factorRho(trdat,'ResultingOptMakespan')
  trdat=factorTrack(trdat)
  if(exists('iter')){
    if(max(trdat$Iter)<iter){return(NULL)}
    print(ddply(trdat,~Problem+Track+Supervision+Extended,
                summarise,minPID=min(PID),maxPID=max(PID)))
    # make sure to shift them to lower pid (for validation split later on)
    trdat=ddply(trdat,~Problem+Track,mutate,PID=PID-min(PID)+1)
  }
  if(dim=='10x10'){
    trdat=subset(trdat,PID<=Ntrain10x10 | (Track=='OPT' & Extended==T))
  } else {
    trdat=subset(trdat,PID<=Ntrain6x5 | (Track=='OPT' & Extended==T))
  }
  print(summary(trdat$Track))
  return(trdat)
}


get.CDR <- function(files,NrFeat,Model,sets='train'){

  get.CDR1 <- function(file,set){
    if(grepl('.csv$',file)){file=substr(file,1,stringr::str_length(file)-4)}
    model.rex="(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9x]+).(?<Rank>[a-z]).(?<Track>[A-Z]{2}[A-Z0-9]+).(?<Probability>[a-z0-9]+).weights.time"
    m=regexpr(model.rex,file,perl=T)
    problem = getAttribute(file,m,1)
    dim=getAttribute(file,m,2)
    Rank=getAttribute(file,m,3)
    Track=getAttribute(file,m,4)
    Prob=getAttribute(file,m,5)

    fname=paste('../PREF/CDR',file,paste(paste0('F',NrFeat),paste0('Model',Model),'on',problem,dim,set,'csv',sep='.'),sep='/')
    if(!file.exists(fname)){return(NULL)}
    dat=read.csv(fname)
    dat$Problem=problem
    dat$NrFeat=NrFeat
    dat$Model=Model
    dat$Prob=Prob
    dat$Rank=Rank
    dat$Track=Track
    dat$Dimension=dim
    dat$Set=set
    return(dat)
  }

  dat=NULL
  for(set in sets){
    for(file in files){
      dat=rbind(dat,get.CDR1(file,set))
    }
  }
  if(is.null(dat)){return(NULL)}

  dat$Rho=factorRho(dat)
  dat$CDR=factorCDR(dat)
  dat=factorTrack(dat)

  ix=dat$Dimension=='10x10' & dat$Set=='train' & dat$PID > Ntrain10x10
  if(any(ix)) {dat$Set[ix]='test'}
  ix=dat$Dimension=='6x5' & dat$Set=='train' & dat$PID > Ntrain6x5
  if(any(ix)) {dat$Set[ix]='test'}
  dat$Set=factorSet(dat$Set)
  return(dat)
}

get.prefWeights <- function(file,timedependent,asMatrix=F){
  m=regexpr("(?<Problem>[jf].[a-z0-9]+).(?<Dimension>[0-9]+x[0-9]+).",file,perl=T)
  problem=getAttribute(file,m,1)
  weights=read.csv(paste0('../PREF/weights/',file))
  weights=subset(weights,Type=='Weight')
  if(!timedependent){ weights=weights[,c(1:4,6)] } else { weights$mean=NULL };
  if(asMatrix){
    weights$CDR=interaction(paste('F',weights$NrFeat,sep=''),paste('M',weights$Model,sep=''))
    weights=dcast(weights,CDR~Feature,value.var = 'Step.1', fill = 0);
    wmat=as.matrix(weights[,2:ncol(weights)])
    rownames(wmat)=weights$CDR
    return(wmat)
  }
  weights$Problem=problem
  return(weights)
}
