library('stringr')
library('plyr')
library('reshape2')
library('data.table')
#library('readr') # not working properly due to Rcpp package on server

getOPTs <- function(){
  OPT=getfiles('../OPT',updateRho = F, adjust = F); colnames(OPT)[grep('Makespan',colnames(OPT))]='Optimum'
  OPT=subset(OPT,Solved=='opt');
  stat=ddply(OPT,~Problem+Dimension+Set,function(X) data.frame(Optimum = as.list(summary(X$Optimum)),Model.Cnt=nrow(X)))
  print(stat)
  OPT=unique(OPT)
  return(OPT)
}

getfiles=function(dir, pattern = 'rnd|rndn|mc|mxc|jc', fileName = F,updateRho = T, adjust=F){

  if(fileName!=F){ files=fileName } else { files=list.files(path=dir, pattern=pattern,full.names=T) }

  allDat=NULL;
  for(file in files){
    print(file)
    pdat=read.csv(file)

    if(!('Set' %in% colnames(pdat))){ pdat$Set='train' }
    str=str_match(file, "[a-z].[a-z]*.[0-9]+x[0-9]+.[A-Z]{2}[A-Z0-9]+")
    if(!is.na(str)){
      track=as.character(str_match(str, "[A-Z]{2}[A-Z0-9]+"))
      dimension=as.character(str_match(str, "[0-9]+x[0-9]+"))
      problem=as.character(str_match(str, "[a-z].[a-z]*"))
      if(!('Shop'%in% colnames(pdat))) { pdat$Shop=substr(problem,1,1)}
      if(!('Distribution'%in% colnames(pdat))) {pdat$Distribution=substr(problem,3,100) }
      if(!('Problem' %in% colnames(pdat))) { pdat$Problem=problem }
      if(!('Dimension' %in% colnames(pdat))){ pdat$Dimension=dimension }
      if(!('Track' %in% colnames(pdat)) & !is.na(track)){ pdat$Track=track }
    }
    allDat<-rbind(allDat,pdat);
  }

  return(formatData(allDat,updateRho,adjust))
}

getfilesTraining=function(pattern='rnd|rndn|mc|mxc|jc',Global=T,useDiff=F, rank){

  extension = ifelse(useDiff,paste('diff',rank,'csv',sep='.'),'csv')

  local=list.files(path='../trainingData',pattern=paste(pattern,'Local',extension,sep='.'))

  if(Global==T){
    global=list.files(path='../trainingData',pattern=paste(pattern,'Global',extension,sep='.'))

    l=str_split_fixed(local,paste('','Local',extension,sep='.'),2)[,1]
    g=str_split_fixed(global,paste('','Global',extension,sep='.'),2)[,1]

    local=local[which(l %in% g)]
    global=global[which(g %in% l)]

    gDAT=NULL;
    for(file in global){
      gDAT = rbind(gDAT,getfiles('../trainingData',file,updateRho = !useDiff))
    }
  } else {
    gDAT=NULL;
  }

  lDAT=NULL;
  for(file in local){
    lDAT = rbind(lDAT,getfiles('../trainingData',file,updateRho = !useDiff))
  }

  if(!is.null(gDAT)){
    mDAT=join(lDAT,gDAT,by=colnames(gDAT)[colnames(gDAT) %in% colnames(lDAT)])
    if(nrow(mDAT)!=nrow(lDAT)|nrow(mDAT)!=nrow(gDAT)){
      print('Number of rows from global and local do not match')
      return(NULL)
    } else {
      if(any(is.na(mDAT))){ mDAT=na.omit(mDAT) }
      return(mDAT)
    }
  } else { return(lDAT) }
}

getTrainingDataRaw  <- function(problems,dim,tracks,rank='p',useDiff=F, global=F){

  if(length(problems)>1){ problems=paste0('(',paste(problems,collapse='|'),')') }

  ix = tracks=='ALL'
  if(any(ix)){
    tracks=c(tracks,paste(c('OPT','RND',sdrs)))
  }

  ix=substr(tracks,1,2)=='IL'
  if(any(ix)){
    print(tracks[ix])
    m=regexpr('IL(?<iter>[0-9]+)(?<track>[A-Z]+)',tracks[ix],perl=T)
    iter=getAttribute(tracks[ix],m,1)
    super=getAttribute(tracks[ix],m,2)
    tracks[ix]=paste0('IL[0-',iter,']',super)
    tracks=c('OPT',tracks)
  }

  allDat=NULL
  for(track in unique(tracks)){
    dat <- getfilesTraining(Global = global, pattern = paste(problems,dim,track,sep='.'), useDiff = useDiff, rank = rank)
    allDat=rbind(allDat,dat)
  }

  if(is.null(allDat)){return(NULL)}

  allDat = subset(allDat,Set=='train')
  print(summary(allDat$Track))

  if(exists('iter')){ if(max(allDat$Iter)!=iter){return(NULL)} }

  return(allDat)
}

getSingleCDR=function(logFile,NrFeat,Model,problem=NULL,dimension=NULL,set='train'){

  if(grepl('.csv$',logFile)){logFile=substr(logFile,1,str_length(logFile)-4)}

  model.rex="(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9x]+).(?<Rank>[a-z]).(?<Track>[A-Z]{2}[A-Z0-9]+).(?<Probability>[a-z0-9]+).weights.time"
  m=regexpr(model.rex,logFile,perl=T)
  if(is.null(problem)){ problem = getAttribute(logFile,m,1) }
  if(is.null(dimension)){ dimension = getAttribute(logFile,m,2)}
  Track=getAttribute(logFile,m,4)
  Prob=getAttribute(logFile,m,5)

  fname=paste('../liblinear','CDR',logFile,paste(paste('F',NrFeat,sep=''),paste('Model',Model,sep=''),'on',problem,dimension,set,'csv',sep='.'),sep='/')
  if(!file.exists(fname)){return(NULL)}
  dat=read.csv(fname)
  dat$Problem=problem
  dat$NrFeat=NrFeat
  dat$Model=Model
  dat$Prob=Prob
  dat$Track=Track

  return(dat)
}

getBestCDR=function(best.model){
  CDR=NULL

  for(r in 1:nrow(best.model)){
    problem=best.model[r,'Problem']

    for(var in colnames(best.model)[2:ncol(best.model)]){
      m=str_split_fixed(best.model[r,var],'.csv.',2)
      n=str_split_fixed(m[2],'[.]',2)
      dat=getSingleCDR(m[1],n[1],n[2])
      if(!is.null(dat)){
        dat$Best=factor(var)
        CDR <- rbind(CDR,dat)
      }
    }
  }
  return(formatData(CDR) )
}
