require(readr)

get.files <- function(dir, files, addFileNameColumn=F){
  dat=NULL
  print(files)
  for(file in files){
    tmp=read_csv(paste(dir,file,sep='/'))
    if(addFileNameColumn) {tmp$File=file}
    dat=rbind(dat,tmp)
  }
  return(dat)
}

get.files.OPT <- function(){
  opt=get.files(paste0(DataDir,'OPT'), list.files(paste0(DataDir,'OPT')))
  rownames(opt)=opt$Name
  opt=subset(opt,!is.na(Optimum))
  opt=factorFromName(opt)
  return(opt)
}

get.files.SDR <- function(){
  sdr=get.files(paste0(DataDir,'SDR'), list.files(paste0(DataDir,'SDR')))
  sdr=factorFromName(sdr)
  sdr$SDR=factorSDR(sdr$SDR)
  sdr=subset(sdr, !is.na(SDR))
  sdr$Rho=factorRho(sdr)
  sdr=subset(sdr,!is.na(Rho) & !is.na(SDR))
  return(sdr)
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
      file=list.files(paste0(DataDir,'Training'), paste('^trdat',problem,dim,track,fileEnd,sep='.'),
                      full.names = T)
      if(length(file)>0){
        dat=read_csv(file)
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


get.CDR <- function(files,nrFeat,model,sets='train'){

  get.CDR1 <- function(file,set){
    if(grepl('.csv$',file)){file=substr(file,1,stringr::str_length(file)-4)}
    model.rex="(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9x]+).(?<Rank>[a-z]).(?<Track>[A-Z]{2}[A-Z0-9]+).(?<Bias>[a-z0-9]+).weights.time"
    m=regexpr(model.rex,file,perl=T)
    problem = getAttribute(file,m,1)
    dim=getAttribute(file,m,2)
    Rank=getAttribute(file,m,3)
    Track=getAttribute(file,m,4)
    Bias=getAttribute(file,m,5)

    fname=paste(DataDir,'PREF/CDR/',file,paste(problem,dim,set,'csv',sep='.'),sep='/')
    if(!file.exists(fname)){return(NULL)}
    dat=read_csv(fname)
    dat$Bias=Bias
    dat$Rank=Rank
    dat$Track=Track
    return(dat)
  }

  dat=NULL
  for(set in sets){
    for(file in files){
      dat=rbind(dat,get.CDR1(file,set))
    }
  }
  if(is.null(dat)){return(NULL)}

  dat = factorFromCDR(dat)
  dat = factorTrack(dat)
  dat = subset(dat,NrFeat == nrFeat & Model == model)
  dat = factorFromName(dat)
  dat$Rho = factorRho(dat)

  ix=dat$Dimension=='10x10' & dat$Set=='train' & dat$PID > Ntrain10x10
  if(any(ix)) {dat$Set[ix]='test'}
  ix=dat$Dimension=='6x5' & dat$Set=='train' & dat$PID > Ntrain6x5
  if(any(ix)) {dat$Set[ix]='test'}
  return(dat)
}

get.prefWeights <- function(file,timedependent,asMatrix=F){
  m=regexpr("(?<Problem>[jf].[a-z0-9]+).(?<Dimension>[0-9]+x[0-9]+).",file,perl=T)
  problem=getAttribute(file,m,1)
  weights=read_csv(paste0(DataDir,'PREF/weights/',file))
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
