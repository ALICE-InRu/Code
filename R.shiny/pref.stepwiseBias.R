get.CDR.stepwiseBias <- function(problems,dim,track='OPT',rank='p'){
  CDR.independent=get.CDR(get.CDR.file_list(problems,dim,track,rank,F,'*'),16,1)
  CDR.independent=subset(CDR.independent,Extended==F)
  CDR.independent$Stepwise = F
  CDR.dependent=get.CDR(get.CDR.file_list(problems,dim,track,rank,T,'*'),16,1)
  CDR.dependent=subset(CDR.dependent,Extended==F)
  CDR.dependent$Stepwise = T

  CDR=rbind(CDR.independent,CDR.dependent)
  CDR$Stepwise <- factor(CDR$Stepwise,levels=c(T,F))
  CDR<-factorBias(CDR)
  return(CDR)
}

plot.CDR.stepwiseBias <- function(CDR,save=NA){

  p <- pref.boxplot(CDR,NULL,'Stepwise','Bias',xText = 'Stepwise model',lineTypeVar = 'Adjusted')

  if(!is.na(save)){
    dim=ifelse(length(levels(CDR$Dimension))==1,as.character(CDR$Dimension[1]),'ALL')
    fname=paste(subdir,paste('bias','boxplotRho','CDR',dim,extension,sep='.'),sep='/')
    if(save=='half'){
      ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
    }
  }
  return(p)
}

table.CDR.stepwiseBias <- function(CDR){
  stat <- rho.statistic(CDR,c('Bias','Adjusted'))
  stat <- arrange(stat, Problem, Training.Rho, Test.Rho) # order w.r.t. lowest mean
  return(xtable(stat))
}

plot.stepwiseBiases <- function(problems,dim,biases,track='OPT',rank='p',adjust2PrefSet=F,save=NA){

  steps=1:(numericDimension(dim)-1)
  w.stepwiseBias <- function(problem,bias){
    w=get.stepwiseBias(steps,problem,dim,bias,rank,track,adjust2PrefSet)
    df=data.frame('Step'=steps,'Probability'=w,'Problem'=problem,'Bias'=bias)
    return(df)
  }

  dat <- do.call(rbind, lapply(problems, function(problem){
    do.call(rbind, lapply(biases, function(bias){
      w.stepwiseBias(problem,bias)
    }))}))

  dat$Problem <- factorProblem(dat,F)
  p=ggplot(dat,aes(x=Step,y=log(Probability),color=Bias))+
    geom_line()+
    axisCompact+facet_grid(~Problem)+
    ggplotColor('Bias',length(biases))

  if(!is.na(save)){
    fname=paste(subdir,paste('bias','CDR',dim,extension,sep='.'),sep='/')
    if(save=='half'){
      ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
    }
  }
  return(p)
}

ks.CDR.stepwiseBias <- function(CDR,variable='Bias'){
  CDR=subset(CDR,Set=='train')
  levels(CDR$Bias)=c(levels(CDR$Bias),'Stepwise')
  CDR$Bias[CDR$Stepwise==T]='Stepwise'
  id.vars=setdiff(c('Problem','Dimension','Adjusted','Bias'),variable)
  ks=ks.CDR(CDR,variable,c('CDR',id.vars))
  print(tidyr::spread(melt(ks,id.vars),'Problem','value'))
}

stats.CDR.stepwiseBias <- function(CDR){
  CDR=subset(CDR,Set=='train')
  stat=arrange(ddply(CDR,~Problem+Stepwise+Bias+Adjusted,function(x) summary(x$Rho)),Problem,Mean)
  return(stat)
}
