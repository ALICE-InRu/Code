get.CDR.Rollout <- function(problems,dimension){
  files = list.files(paste(DataDir,'PREF','CDR',sep='/'),'Globalweights|SDRweights')
  files = files[grepl(paste(paste(problems,dimension,sep='.'),collapse = '|'),files)]
  CDR <- get.CDR(files)
  CDR$BestRho <- factorRho(CDR,'BestFoundMakespan')
  CDR$CDR = factor(CDR$CDR, levels=sort(levels(CDR$CDR)))
  return(CDR)
}

stat.Rollout <- function(CDR){
  CDR = CDR.fortified(CDR)
  CDR$Problem <- factorProblem(CDR,F)
  ddply(CDR,~Problem+Dimension+Bias+Track+NrFeat+Fortified+Set,function(x) summary(x$Rho))
}

CDR.fortified <- function(CDR){
  if(is.null(CDR)) { return(NULL)}
  if(any(grepl('Fortified',colnames(CDR)))){ return(CDR) }
  if(!any(grepl('Best',colnames(CDR)))){
    CDR$Fortified=F
    return(CDR)
  }
  if(!any(CDR$BestFoundMakespan<CDR$Makespan))
  {
    CDR$Fortified=F
    return(CDR)
  }
  normal = CDR
  normal$Fortified=F
  fortified = CDR
  fortified$Rho = fortified$BestRho
  fortified$Makespan = fortified$BestFoundMakespan
  fortified$Fortified=T
  CDR=rbind(normal,fortified)
  CDR=CDR[,grep('Best',colnames(CDR),invert = T)]
  return(CDR)
}

boxplot.rollout <- function(CDR,CDR.compare=NULL){
  if(!any(grepl('Fortified',colnames(CDR)))){ CDR=CDR.fortified(CDR) }
  CDR$CDR = interaction(CDR$CDR,CDR$Track)
  p=pref.boxplot(CDR,CDR.compare,'Bias',xText = 'Bias', lineTypeVar = 'Fortified')
  if(!is.null(CDR.compare)){
    p=p+ggplotFill('Ref. CDR',max(c(2,length(levels(CDR.compare$SDR)))))
  }
  return(p)
}

get.CDR.Rollout.Compare <- function(CDR.global,dim,singleCnt=3){

  CDR.global=droplevels(CDR.global)
  tracks = levels(CDR.global$Track)
  biases = unique(CDR.global$Bias)
  problems = unique(CDR.global$Problem)

  CDR.local = do.call(rbind, lapply(biases, function(bias){
    file_list = get.CDR.file_list(problems,dim,tracks,'p',F,bias)
    get.CDR(file_list,nrFeat = 16,modelID = 1)
    }))

  CDR.single <- get.SingleFeat.CDR(problems, dim)
  CDR.single <- subset(CDR.single,FeatureType == 'Global')

  CDR.global = CDR.fortified(CDR.global)
  CDR.local = CDR.fortified(CDR.local)

  CDR.single = CDR.fortified(CDR.single)
  CDR.single$Rank='NA'
  CDR.single$Bias='equal'
  CDR.single$Track=interaction(factorFeature(CDR.single$Feature),CDR.single$Extremal)
  CDR.single$NrFeat=1
  CDR.single$Model=factorFeature(CDR.single$Feature,F)
  CDR.single$ID = as.numeric(stringr::str_match(CDR.single$Model,"[0-9]+"))
  CDR.single$CDR=paste0('1.',CDR.single$ID)
  CDR.single$Extended=F
  CDR.single <- subset(CDR.single, ID>20 | Fortified==F)
  CDR.single$TrainingData <- interaction(CDR.single$Problem,CDR.single$Dimension,sep=' ')

  best=ddply(CDR.single, ~Problem+Dimension, function(x){
    tmp=ddply(subset(x,Set=='train'), ~Track,summarise,mu=mean(Rho))
    tmp=arrange(tmp,mu)
    return(as.character(tmp$Track[1:singleCnt]))
  })
  best=melt(best,c('Problem','Dimension'),value.name = 'Track')
  CDR.single = subset(CDR.single, Track %in% best$Track & Problem %in% best$Problem)

  CDR=rbind(CDR.global,CDR.local,CDR.single[,colnames(CDR.single) %in% colnames(CDR.global)])
  return(CDR)
}

