source('optimalityOfDispatches.R')

estimateStepwiseOptimality <- function(dimension,problem=NULL,pat='p.OPT.equal.weights.timeindependent'){
  
  models=list.files(paste('../liblinear/',dimension,sep='/'),'^exhaust')
  if(!is.null(problem)){ models=models[grep(paste('exhaust',problem,dimension,sep='.'),models)] }
  models=models[grep(pat,models)]
  
  for(model in models){
    opt.acc=findStepwiseCDRoptimality(model)    
  }
  return(opt.acc)
}







plotLiblinearModels <- function(problems,dim,rank,tracks,timedependent,probabilities,plotSeparately,exhaustive){
  
  return(list(Probability=prob,Pareto.front=dat.fronts,Liblinear.Summary=pref))  
}




best.liblinearBoxplot <- function(best.model, prob, SDR=NULL){
  
  CDR = getBestCDR(best.model)
  if(is.null(CDR)){return(NULL)}
  
  p=liblinearBoxplot(CDR,SDR,'Best')
  
  dimension=ifelse(length(unique(CDR$Dimension))==1,as.character(CDR$Dimension[1]),'dim')
  fname=paste(subdir,paste('boxplotRho','CDR',dimension,prob,extension,sep='.'),sep='/')
  if(!file.exists(fname)|redoPlot){ ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi) }
  return(p)
}


if(FALSE){
  
  dat=read.csv('../liblinear/10x10/exhaust.j.rnd.10x10.p.OPT.equal.weights.timeindependent.csv')
  
  acc=subset(dat,Type!='Weight'); acc$Feature=NULL
  best.acc=ddply(acc,~NrFeat,summarise,Model=Model[mean==max(mean)]); 
  print(best.acc)
  
  acc=subset(acc, interaction(NrFeat,Model) %in% interaction(best.acc$NrFeat,best.acc$Model))
  macc=melt(acc,measure.vars = colnames(acc)[grep('Step',colnames(acc))])
  macc$Step=as.numeric(substr(macc$variable,6,100))
  macc$value=macc$value/100
  p.acc=ggplot(macc,aes(x=Step,y=value,color=as.factor(NrFeat),order=as.factor(Model)))+facet_grid(Type~.)+geom_line()+theme(legend.position='bottom')
  print(p.acc)
  
  weight=subset(dat,Type=='Weight'); weight$mean=NULL
  weight=subset(weight, interaction(NrFeat,Model) %in% interaction(best.acc$NrFeat,best.acc$Model))
  
  mweight=melt(weight,measure.vars = colnames(weight)[grep('Step',colnames(weight))])
  mweight=subset(mweight,value!=0)
  mweight$Step=as.numeric(substr(mweight$variable,6,100))
  mweight = ddply(mweight,~NrFeat+Model+Step,mutate,sc.value=value/sqrt(sum(value*value)))
  p.weight=ggplot(mweight,aes(x=Step,y=sc.value,color=Feature,order=Model))+geom_line()+facet_wrap(~NrFeat+Model,ncol=1)
  print(p.weight)
  
}

