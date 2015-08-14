get.CDR.stepwiseBias <- function(problems,dim,track='OPT',rank='p',timedependent=F){
  CDR=get.CDR(get.CDR.file_list(problems,dim,track,rank,timedependent,'*'),16,1)
  CDR=subset(CDR,Extended==F)
  CDR$Bias<-factorBias(CDR$Bias)
  return(CDR)
}

plot.CDR.stepwiseBias <- function(CDR,save=NA){
  p <- pref.boxplot(CDR,NULL,'Bias',tiltText = F,xText = 'Bias')

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
  stat <- rho.statistic(CDR,c('Bias'))
  stat <- arrange(stat, Problem, Training.Rho, Test.Rho) # order w.r.t. lowest mean
  return(xtable(stat))
}

plot.stepwiseBiases <- function(problems,dim,biases){

  steps=1:numericDimension(dim)
  w.stepwiseBias <- function(problem,bias){
    w=get.stepwiseBias(steps,problem,dim,bias)
    df=data.frame('Step'=steps,'Weight'=w,'Problem'=problem,'Bias'=bias)
    return(df)
  }

  dat <- do.call(rbind, lapply(problems, function(problem){
    do.call(rbind, lapply(biases, function(bias){
      w.stepwiseBias(problem,bias)
    }))}))

  ggplot(dat,aes(x=Step,y=Weight,color=Bias))+geom_line()+scale_x_continuous(expand=c(0,0))+facet_grid(~Problem)+
    ggplotColor('Bias',length(biases))
}
