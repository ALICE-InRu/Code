source('global.R')

get.CDR.Rollout <- function(problems,dimension){
  files = list.files(paste(DataDir,'PREF','CDR',sep='/'),'Globalweights')
  files = files[grepl(paste(paste(problems,dimension,sep='.'),collapse = '|'),files)]
  CDR <- get.CDR(files)
  CDR$BestRho <- factorRho(CDR,'BestFoundMakespan')
  return(CDR)
}

stat.Rollout <- function(CDR,fortifiedRho=F){
  CDR$Problem <- factorProblem(CDR,F)
  var = ifelse(fortifiedRho,'BestRho','Rho')
  ddply(CDR,~Problem+Dimension+Bias+Track+NrFeat+Set,function(x) c(summary(x[,var]),N=nrow(x)))
}

CDR.fortified <- function(CDR){
  if(is.null(CDR)) { return(NULL)}
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
  pref.boxplot(CDR,CDR.compare,'Bias',xText = 'Stepwise bias', lineTypeVar = 'Fortified')
}

input <- list(problems=c('j.rnd','f.rnd'),dimension='6x5')
CDR.global=get.CDR.Rollout(input$problems,input$dimension)
stat.Rollout(CDR.global,F)
stat.Rollout(CDR.global,T)

source('pref.trajectories.R'); source('cmaes.R'); source('feat.R')
tracks='CMAESMINRHO'; #c('LWR','MWR','CMAESMINRHO','CMAESMINCMAX')
CDR.compare <- get.CDRTracksRanksComparison(input$problems,input$dimension,tracks)
CDR.compare <- subset(CDR.compare, SDR %in% c('ES.rho','ES.Cmax') |
                        (stringr::str_sub(Problem,1,1)=='j' & SDR=='MWR')|
                        (stringr::str_sub(Problem,1,1)=='f' & SDR=='LWR'))

get.CDR.Rollout.Compare <- function(CDR.global,dim){

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
  CDR.single$Bias='NA'
  CDR.single$Track='NA'
  CDR.single$NrFeat=1
  CDR.single$Model=CDR.single$Feature
  CDR.single$Extended=F
  CDR=rbind(CDR.global,CDR.local,CDR.single[,colnames(CDR.single) %in% colnames(CDR.global)])

  return(droplevels(CDR))
}

CDR.full = get.CDR.Rollout.Compare(CDR.global, input$dimension)

boxplot.rollout(CDR.global,CDR.compare)
boxplot.rollout(CDR.full,CDR.compare)
