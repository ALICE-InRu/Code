require(readr)

get.files <- function(dir, files=NULL, addFileNameColumn=F){
  if(is.null(files)){
    file_list = list.files(dir,full.names = T)
  } else {
    file_list=paste(dir,files,sep='/')
  }
  if(addFileNameColumn){
    dat <- do.call(rbind, lapply(file_list, function(X) { data.frame(File = basename(X), read_csv(X))} ))
  } else {
    dat <- ldply(file_list, read_csv)
  }
  return(dat)
}

get.files.OPT <- function(){
  opt=get.files(paste0(DataDir,'OPT'))
  rownames(opt)=opt$Name
  opt=subset(opt,!is.na(Optimum))
  opt=factorFromName(opt)
  opt = arrange(opt,Problem,Dimension,Set,PID)
  ix=which(is.na(opt$GivenName))
  opt$tmp = factor(substr(opt$Problem,3,100),
                   levels=c('rnd','rndn','rnd_p1mdoubled','rnd_pj1doubled','jc','mc','mxc'),
                   labels=c('random','random-narrow','random with job variation',
                            'random with machine variation','job-correlated','machine-correlated',
                            'mixed-correlated'))
  opt$GivenName = factor(opt$GivenName, levels=c(levels(opt$tmp),unique(opt$GivenName)))
  opt$GivenName[ix]=opt$tmp[ix]
  return(opt[,c('Name','Problem','Dimension','Set','PID','Optimum','Solved','GivenName')])
}

get.files.SDR <- function(){
  sdr=get.files(paste0(DataDir,'SDR'))
  sdr=factorFromName(sdr)
  sdr$SDR=factorSDR(sdr$SDR)
  sdr$Rho=factorRho(sdr)
  sdr=subset(sdr,!is.na(Rho))
  return(sdr)
}

get.files.SDR.ORLIB <- function(){
  files=list.files(paste0(DataDir,'SDR'),pattern = 'ORLIB')
  sdr=get.files(paste0(DataDir,'SDR'),files = files)
  sdr=factorFromName(sdr)
  sdr$SDR=factorSDR(sdr$SDR)
  sdr$Rho=factorRho(sdr)
  sdr=subset(sdr,!is.na(Rho))
  sdr$Problem <- factorProblem(sdr,F)
  return(sdr)
}


get.files.TRDAT <- function(problems,dim,tracks,rank='p',useDiff=F,Global=F){
  fileEnd = ifelse(useDiff,paste0('.diff.',rank),'')
  fileEnd = paste0(ifelse(Global,'Global','Local'),fileEnd,'.csv')

  ix = tracks=='ALL'
  if(any(ix)){ tracks=c(tracks[-ix],paste(c('OPT','RND',sdrs,'CMAESMINRHO','CMAESMINCMAX'))) }
  ix=substr(tracks,1,2)=='IL'
  if(any(ix)){
    m=regexpr('IL(?<Iter>[0-9]+)(?<Track>[A-Z]+)',tracks[ix],perl=T)
    iter=getAttribute(tracks[ix],m,'Iter')
    super=getAttribute(tracks[ix],m,'Track')
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
  print(summary(trdat$Track))
  return(trdat)
}

get.CDR.file_list <- function(problems,dim,tracks,ranks,timedependent,bias='equal',lmax=F){
  if(length(problems)>1) problems=paste0('(',paste(problems,collapse='|'),')')
  ix=grepl('IL',tracks)
  if(any(ix)){ tracks[ix]=paste0(substr(tracks[ix],1,2),'[0-9]+',substr(tracks[ix],3,100)) }
  if(length(tracks)>1) tracks=paste0('(',paste(tracks,collapse='|'),')')
  if(length(ranks)>1) ranks=paste0('(',paste(ranks,collapse='|'),')')
  file_list=list.files(paste0(DataDir,'PREF/CDR/'),paste(problems,dim,ranks,tracks,bias,'weights',ifelse(timedependent,'timedependent','timeindependent'),sep='.'))
  file_list=file_list[grep('lmax',file_list,invert = !lmax)]
  return(file_list)
}

get.SingleFeat.CDR <- function(problems,dim,set='train'){
  if(length(problems)>1) problems=paste0('(',paste(problems,collapse='|'),')')
  file_list <- list.files(paste0(DataDir,'SingleFeat/CDR'),full.names = T, recursive = T,
                          pattern=paste(problems,dim,set,'csv',sep='.'))

  CDR <- do.call(rbind,lapply(file_list, function(file) {
    dat=read_csv(file)
    if(!any(grepl('BestFoundMakespan',colnames(dat)))){ dat$BestFoundMakespan=dat$Makespan }
    return(dat)
  } ))
  if(is.null(CDR)) {return(NULL)}

  CDR <- factorFromName(CDR)

  CDR$Rho <- factorRho(CDR)
  CDR$RhoFortified <- factorRho(CDR,var = 'BestFoundMakespan')
  CDR <- subset(CDR, !is.na(Rho))

  model.rex="phi.(?<Feature>[a-zA-Z]+).E(?<Extremal>-?[0-9])"
  m=regexpr(model.rex,CDR$CDR,perl=T)
  CDR$Feature = getAttribute(CDR$CDR,m,'Feature')
  CDR$Extremal = getAttribute(CDR$CDR,m,'Extremal',asStr = F)
  CDR$Extremal = factor(CDR$Extremal, levels=c(-1,1),labels=c('min','max'))
  CDR$Feature <- factorFeature(CDR$Feature)
  CDR$FeatureType = factorFeatureType(CDR$Feature)

  return(CDR)
}

get.many.CDR <- function(file_list,sets,NrFeat=16,ModelID=1){
  CDR <- ldply(sets, function(set) get.CDR(file_list, NrFeat, ModelID, set))
  return(CDR)
}

get.CDR <- function(file_list,nrFeat=NULL,modelID=NULL,sets=c('train','test')){

  get.CDR1 <- function(file,set){
    model.rex="(?<Problem>[a-z].[a-z_1]+).(?<Dimension>[0-9x]+).(?<Rank>[a-z]).(?<Track>[A-Z]{2}[A-Z0-9]+).(?<Bias>[a-z0-9]+).weights.time"
    m=regexpr(model.rex,file,perl=T)
    problem = getAttribute(file,m,'Problem')
    dim=getAttribute(file,m,'Dimension')
    Rank=getAttribute(file,m,'Rank')
    Track=getAttribute(file,m,'Track')
    Bias=getAttribute(file,m,'Bias')
    lmax=grepl('lmax',file)

    fname=paste(DataDir,'PREF/CDR/',file,paste(problem,dim,set,'csv',sep='.'),sep='/')
    if(!file.exists(fname)){return(NULL)}
    dat=read_csv(fname)
    dat$Bias=Bias
    dat$Rank=Rank
    dat$Track=Track
    if(lmax){ dat$lmax=getAttribute(file,regexpr('_lmax(?<lmax>[0-9]+)',file,perl=T),'lmax',F) }

    return(dat)
  }



  dat <- do.call(rbind, lapply(sets, function(set) { ldply(file_list, get.CDR1, set)} ))
  dat <- factorFromCDR(dat)
  if(!is.null(nrFeat) & !is.null(modelID)){ # otherwise whole set returned
    dat <- subset(dat,NrFeat == nrFeat & Model == modelID)
  }

  dat <- factorFromName(dat)
  dat$Rho <- factorRho(dat)
  dat <- subset(dat, !is.na(Rho))

  dat <- factorTrack(dat)
  dat$Set <- factorSet(dat$Set)

  ix=which(dat$Dimension=='10x10' & !dat$Extended & dat$Set=='train' & dat$PID>300)
  if(any(ix)){ dat$Set[ix] = 'test' }
  ix=which(dat$Dimension=='6x5' & !dat$Extended & dat$Set=='train' & dat$PID>500)
  if(any(ix)){ dat$Set[ix] = 'test' }

  return(dat)
}

ks.CDR <- function(CDR,variable='Rank',variables=c('Problem','Dimension','Track','Rank'),
                   alpha=0.05,set='train'){

  CDR$Problem <- factorProblem(CDR,F)
  if('train' %in% CDR$Set) {CDR=subset(CDR,Set==set)}
  CDR=droplevels(CDR[,colnames(CDR) %in% c(variables,'variable','Rho','Name')])

  colnames(CDR)[grep(variable,colnames(CDR))]='variable'
  id.vars=setdiff(variables,variable)

  vars = levels(factor(CDR$variable))
  y=tidyr::spread(CDR,variable,'Rho')
  y=y[rowSums(is.na(y))==0,]
  nrow(y)

  ks2 <- function(i,j){
    suppressWarnings(
      ks <- ddply(y,id.vars,
                  function(x){
                    ks.test2(x[,vars[i]], x[,vars[j]])
                    }))
    colnames(ks)[ncol(ks)]=paste('H:',vars[i],'!=',vars[j])
    return(ks)
  }

  ks=ks2(1,2)
  if(length(vars)>2){
    comb=as.data.frame(t(combn(length(vars),2)))
    for(k in 2:nrow(comb)){
      ks = join(ks,ks2(comb[k,1],comb[k,2]),id.vars)
    }
  }
  return(ks)
}


get.prefWeights <- function(model,asMatrix=F){
  m=regexpr("(?<Problem>[jf].[a-z0-9]+).(?<Dimension>[0-9]+x[0-9]+).",model,perl=T)
  timedependent=grepl('timedependent',model)
  problem=getAttribute(model,m,'Problem')
  weights=read_csv(paste0(DataDir,'PREF/weights/',model,'.csv'))
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
