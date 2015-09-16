get.evolutionCMA <- function(problems,dim,Timedependent=T,Timeindependent=T,meanStep=F){
  get.evolutionCMA1 <- function(problem,type,timedependent){
    file=paste('output',problem,dim,type,'weights',
               ifelse(timedependent,'timedependent','timeindependent'),'csv',sep='.')
    file=paste0(DataDir,'CMAES/results/',file)
    if(!file.exists(file)) { return(NULL) }
    x <- read_csv(file)
    x=subset(x, Generation==1 | Generation %% 10 == 0 | Generation==max(Generation)) # otherwise too much data
    pat='phi.(?<Feature>[a-zA-Z]+).(?<Step>[0-9]+)'
    x=melt(x[,c(1:3,grep(pat,names(x),perl=T))], id.vars=c('Generation','CountEval','Fitness'))
    m=regexpr(pat,x$variable,perl=T)
    x$Step=getAttribute(x$variable,m,'Step',F)
    if(meanStep & timedependent){
      x=ddply(x,~Generation+CountEval+Fitness+variable,summarise,value=mean(value), .progress = 'text')
    } else if (Timeindependent) { x=subset(x,Step==1)}
    x$Feature=factorFeature(getAttribute(x$variable,m,'Feature'))
    x$ObjFun=type
    return(x)
  }
  get.evolutionCMA2 <- function(problem,timedependent){
    stat=rbind(get.evolutionCMA1(problem,'MinimumMakespan',timedependent),
               get.evolutionCMA1(problem,'MinimumRho',timedependent))
    if(is.null(stat)) return(NULL)
    stat$Timedependent=timedependent
    stat$Problem=problem
    stat$Dimension=dim
    return(stat)
  }
  stat=NULL
  for(problem in problems){
    if(Timedependent) stat=rbind(stat,get.evolutionCMA2(problem,T))
    if(Timeindependent) stat=rbind(stat,get.evolutionCMA2(problem,F))
  }
  if(is.null(stat)) {return(NULL)}
  info=ddply(stat,~Problem+ObjFun+Timedependent,summarise,Generation=max(Generation),CountEval=max(CountEval))
  info=merge(tidyr::spread(info[,-4],'ObjFun','CountEval'),
             tidyr::spread(info[,-5],'ObjFun','Generation'),
             by=c('Problem','Timedependent'),
             suffixes = c(".CountEval",".Generation"))
  return(stat)
}

plot.evolutionCMA.Weights <- function(evolutionCMA,timedependent=F){
  x=subset(evolutionCMA,Timedependent==timedependent)
  if(timedependent){
    x = get.evolutionCMA(unique(x$Problem),unique(x$Dimension),T,F,F) # get missing steps
    x = ddply(x, ~Problem+Dimension+Timedependent+Step+Feature+ObjFun, function(x) { x[nrow(x), ] })
  }
  x$Problem <- factorProblem(x, F)
  x$ObjFun <- factorCMAObjFun(x$ObjFun)
  #x=ddply(x,~Problem+Dimension+ObjFun+Generation+Timedependent,mutate,
  #        sc.weight=value/sqrt(sum(value*value)))
  x$Feature=factorFeature(x$Feature,F)

  nFacets = length(unique(interaction(x$Problem,x$Dimension,x$ObjFun)))
  nCol=ceiling(sqrt(nFacets)/2)*2

  p=ggplot(x,aes(y=value,color=Feature,linetype=Timedependent))+
    cornerLegend(nFacets,ncol = nCol)+
  guides(linetype = guide_legend(title.position = 'top'),
           color=guide_legend(ncol=4,byrow=TRUE, title.vjust=0.25,
                              title.theme = element_text(size=11, face="bold", angle = 90)))+
    ggplotColor('Feature',length(levels(x$Feature)))+
    labs(linetype="Stepwise") + ylab(expression("Weight" *~ w[i] )) +
    axisCompact+facet_wrap(~Problem+Dimension+ObjFun,ncol=nCol,scales='free_x')

  if(timedependent) {
    p = p + geom_line(aes(x=Step))
  } else {
    p = p + geom_line(aes(x=Generation))
  }

  return(p)
}

last.evolutionCMA <- function(evolutionCMA,printOut=T){
  evolutionCMA$ObjFun <- factorCMAObjFun(evolutionCMA$ObjFun)
  objFuns=levels(evolutionCMA$ObjFun)

  vars=c('Generation','CountEval','Fitness')
  if(!printOut) { vars=c(vars,'ObjFun') }

  stat1 <- function(evolutionCMA){
    ddply(evolutionCMA, ~Problem+Dimension+Timedependent, function(x) {
      x[nrow(x), vars] })
  }
  if(printOut){
    stat <- merge(stat1(subset(evolutionCMA,ObjFun==objFuns[1])),
                  stat1(subset(evolutionCMA,ObjFun==objFuns[2])),
                  by=c('Problem','Dimension','Timedependent'),
                  suffixes = paste0('.',objFuns),all = T)
    stat$Problem = factorProblem(stat,F)
    stat$Dimension = factorDimension(stat)
    stat=arrange(stat,Dimension,Problem, Timedependent)
    xtable(stat)
  } else {
    stat <- rbind(stat1(subset(evolutionCMA,ObjFun==objFuns[1])),
                  stat1(subset(evolutionCMA,ObjFun==objFuns[2])))
    return(stat)
  }
}

plot.evolutionCMA.Fitness <- function(evolutionCMA){
  evolutionCMA$Problem = factorProblem(evolutionCMA,F)
  evolutionCMA$Dimension = factorDimension(evolutionCMA)
  evolutionCMA$TrainingData = interaction(evolutionCMA$Problem,evolutionCMA$Dimension)
  evolutionCMA$ObjFun <- factorCMAObjFun(evolutionCMA$ObjFun)
  p <- ggplot(evolutionCMA,aes(x=Generation, y=log(Fitness))) +
    #ylab('Fitness value') +
    geom_line(aes(linetype = Timedependent, color=Problem,size=Dimension)) +
    facet_grid(ObjFun~., scales = 'free') +
    ggplotColor('Problem',length(levels(evolutionCMA$Problem))) +
    scale_size_manual('Size',values=c(0.5,1)) +
    labs(linetype="Stepwise")+
    guides(linetype=guide_legend(ncol=1,byrow=TRUE,title.position = 'top'),
           size=guide_legend(ncol=1,byrow=TRUE,title.position = 'top'),
           color=guide_legend(nrow=3,byrow=TRUE))

  return(p)
}

get.CDR.CMA <- function(problems,dim,times=c(T,F),objFuns=c('MinimumRho','MinimumMakespan'),testProblems=NULL){

  get.CDR1 <- function(problem,objFun,timedependent) {
    dir=paste0(DataDir,'CMAES/CDR/',paste('full',problem,dim,objFun,'weights',ifelse(timedependent,'timedependent','timeindependent'),sep='.'))
    if(is.null(testProblems)) { testProblems = paste(problem,dim,sep='.') }

    files=list.files(dir,paste(testProblems,collapse = '|'))
    if(length(files)==0){return(NULL)}
    CDR = get.files(dir,files)
    CDR$ObjFun = objFun
    CDR$TrainingData <- problem
    CDR$Timedependent=timedependent
    return(CDR)
  }

  CDR <- do.call(rbind, lapply(objFuns, function(objFun) {
    do.call(rbind, lapply(times, function(timedependent) {
      ldply(problems, get.CDR1, objFun,timedependent)}))}))

  CDR <- factorFromName(CDR)
  CDR$ObjFun <- factorCMAObjFun(CDR$ObjFun)
  CDR$Rho <- factorRho(CDR)
  CDR$TrainingData <- factorProblem(CDR, simple = F, 'TrainingData')
  CDR$TrainingData <- factor(paste(CDR$TrainingData,dim), levels=paste(levels(CDR$TrainingData),dim))

  return(CDR)

}

plot.CMABoxplot <- function(CDR,SDR=NULL){
  if(!any(grepl('ORLIB',CDR$Problem,ignore.case = T))){
    pref.boxplot(CDR,SDR,'TrainingData', tiltText = T,
                 ColorVar = 'ObjFun', xText = 'CMA-ES objective function',
                 lineTypeVar = 'Timedependent') +
      scale_linetype_manual('Stepwise',values=c(1,2)) +
      facet_grid(Set~Dimension, scales='free', space = 'free_x')
  } else {
    pref.boxplot(CDR,SDR,'TrainingData', tiltText = T,
                 ColorVar = 'ObjFun', xText = 'CMA-ES objective function') +
      facet_wrap(~Problem+Set,scales='free')+ylab(bksLabel)
  }
}


CDR.CMA.ks <- function(CDR,variable='ObjFun',alpha=0.05){
  if('train' %in% CDR$Set) {CDR=subset(CDR,Set=='train')}
  CDR$Makespan=NULL
  CDR$Problem <- factorProblem(CDR,F)
  colnames(CDR)[grep(variable,colnames(CDR))]='variable'

  id.vars=setdiff(c('Problem','TrainingData','Timedependent','ObjFun'),variable)

  vars = levels(factor(CDR$variable))
  y=tidyr::spread(CDR,variable,'Rho')
  y=y[rowSums(is.na(y))==0,]
  suppressWarnings(
  ks <- ddply(y,id.vars,
                  function(x){
                    ks.test2(x[,vars[1]], x[,vars[2]])}))
  colnames(ks)[4]='H'
  return(ks)
}
