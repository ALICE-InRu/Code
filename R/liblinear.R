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


liblinearXtable = function(info,onlyPareto=F){
  if(onlyPareto){info$Pareto.front=subset(info$Pareto.front,Pareto.front==T)}
  library('xtable')
  tmp=ddply(info$Pareto.front,~Problem+NrFeat+Model+Prob,summarise,
            Accuracy.Optimality=round(Validation.Accuracy.Optimality,digit=2),
            Accuracy.Classification=round(Validation.Accuracy.Classification,digit=2),
            Rho=round(Validation.Rho,digit=2),
            Pareto=Pareto.front)
  #sort
  tmp=tmp[order(tmp$Problem,tmp$Rho,-tmp$Accuracy.Optimality,-tmp$Accuracy.Classification),]; 
  tmp$Pareto=factor(tmp$Pareto, levels=c(T,F), labels=c('$\\blacktriangle$',''))
  print(xtable(tmp),include.rownames=FALSE,sanitize.text.function=function(x){x})  
}

liblinearComparedToOptimal <- function(info,dimension){
  
  info$Pareto.front$BestInfo=interaction(info$Pareto.front$File,info$Pareto.front$NrFeat,info$Pareto.front$Model)
  best.model = ddply(info$Pareto.front,~Problem,summarise,Max.Accuracy.Optimality=BestInfo[Validation.Accuracy.Optimality==max(Validation.Accuracy.Optimality)],Min.Rho=BestInfo[Validation.Rho==min(Validation.Rho)])
  
  best=NULL
  for(i in 1:nrow(best.model))
  {
    tmp=subset(info$Pareto.front, Problem==best.model$Problem[i] & BestInfo==best.model$Max.Accuracy.Optimality[i])
    acc=subset(getOptimaltyAccuracy(tmp$File,F),NrFeat==tmp$NrFeat & Model==tmp$Model)
    acc=acc[,c('Step','validation.isOptimal')];colnames(acc)[2]='value'
    acc$Problem=tmp$Problem;
    acc$CDRlbl=tmp$CDRlbl
    acc$variable='Max.Accuracy.Optimality'
    acc$Accuracy='Optimality'
    best=rbind(best,acc)
    acc=subset(getPrefSetAccuracy(tmp$File,'Validation.Accuracy'),NrFeat==tmp$NrFeat & Model==tmp$Model) 
    acc=acc[,c('Step','value')]
    acc$Problem=tmp$Problem;
    acc$CDRlbl=tmp$CDRlbl
    acc$variable='Max.Accuracy.Optimality'
    acc$Accuracy='Classification'
    best=rbind(best,acc)
    
    tmp=subset(info$Pareto.front, Problem==best.model$Problem[i] & BestInfo==best.model$Min.Rho[i])
    rho=subset(getOptimaltyAccuracy(tmp$File,F),NrFeat==tmp$NrFeat & Model==tmp$Model) 
    rho=rho[,c('Step','validation.isOptimal')];colnames(rho)[2]='value'
    rho$Problem=tmp$Problem
    rho$CDRlbl=tmp$CDRlbl    
    rho$variable='Min.Rho'
    rho$Accuracy='Optimality'
    best=rbind(best,rho)    
    rho=subset(getPrefSetAccuracy(tmp$File,'Validation.Accuracy'),NrFeat==tmp$NrFeat & Model==tmp$Model) 
    rho=rho[,c('Step','value')]
    rho$Problem=tmp$Problem
    rho$CDRlbl=tmp$CDRlbl    
    rho$variable='Min.Rho'
    rho$Accuracy='Classification'
    best=rbind(best,rho)    
  } 
  
  p0=plotStepwiseOptimality(unique(info$Pareto.front$Problem),dimension,SMOOTH = F,T)  
  
  p1=p0+facet_wrap(~Problem)+
    geom_line(data=best,aes(y=value,color=variable,size=Accuracy))+
    ggplotColor("Best",2)+scale_size_discrete(range=c(0.5,1.2))+
    ggplotCommon(best,ylab='Probability of CDR being optimal')
  fname=paste(paste(subdir,'trdat',sep='/'),'prob.moveIsOptimal',dimension,'OPT',info$Probability,'best',extension,sep='.')
  if(!file.exists(fname)|redoPlot){ ggsave(p1,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi) }    
  print(p1)
    
  best2=dcast(best,Step+Problem+Accuracy~variable,value.var = 'value')  
  p2=ggplot(best2,aes(x=Step,y=Max.Accuracy.Optimality-Min.Rho))+facet_grid(Accuracy~Problem,scale='free')+
    geom_hline(aes(yintercept=0),color='red')+geom_line()+ 
    ggplotColor("Best",2)+scale_size_discrete(range=c(0.5,1.2))+
    ggplotCommon(best2)
  fname=paste(paste(subdir,'trdat',sep='/'),'prob.moveIsOptimal',dimension,'OPT',info$Probability,'best.diff',extension,sep='.')
  if(!file.exists(fname)|redoPlot){ ggsave(p2,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi) }
  print(p2)
  
  return(best.model)
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

ks.matrix <- function(dat,var,label){
  ks.mat=matrix(nrow=length(dat[,label]),ncol=length(dat[,label]))
  rownames(ks.mat)=dat[,label]
  colnames(ks.mat)=dat[,label]
  
  for(c1 in 1:ncol(ks.mat)){
    for(c2 in 1:ncol(ks.mat)){      
      ks.mat[c1,c2]=ks.test(dat[c1,var][[1]], dat[c2,var][[1]])$p.value
    }
  }
  
  ks.mat <- round(ks.mat, digits = 2)
  return(ks.mat)
}


liblinearKolmogorov <- function(info,problem,onlyPareto=T,SDR=NULL){
  
  if(onlyPareto){
    dat=unique(info$Pareto.front[info$Pareto.front$Pareto.front,])
  } else {
    dat=unique(info$Pareto.front)
  }
  dat=subset(dat,Problem==problem)
    
  dat.Acc=NULL
  dat.Rho=NULL
  for(use in 1:nrow(dat)){    
    tmp=subset(getOptimaltyAccuracy(dat[use,'File'],F),NrFeat==dat[use,'NrFeat'] & Model==dat[use,'Model'])
    tmp$Problem=dat[use,'Problem']    
    tmp$CDRlbl=dat[use,'CDRlbl']
    dat.Acc=rbind(dat.Acc,tmp)
    
    tmp=getSingleCDR(dat[use,'File'],dat[use,'NrFeat'],dat[use,'Model'])    
    tmp$CDRlbl=dat[use,'CDRlbl']    
    dat.Rho=rbind(dat.Rho,tmp)
  }
  dat.Rho=formatData(dat.Rho)
    
  if(!is.null(SDR)){
    SDR <- subset(SDR, Name %in% dat.Rho$Name)    
    SDR$CDRlbl=SDR$SDR  
    dat.Rho=rbind(dat.Rho[,c('Problem','CDRlbl','Rho','Set','PID')],SDR[,c('Problem','CDRlbl','Rho','Set','PID')])  
  } else { dat.Rho=dat.Rho[,c('Problem','CDRlbl','Rho','Set','PID')] }
    
  stat.Rho=ddply(dat.Rho,~Problem+CDRlbl+Set, function(X) data.frame(Rho=I(list(unlist(X$Rho)))))
  stat.Acc=ddply(dat.Acc,~Problem+CDRlbl, function(X) data.frame(isOptimal=I(list(unlist(X$validation.isOptimal)))))
    
  ks.Acc = ks.matrix(stat.Acc,'isOptimal','CDRlbl')          
  ks.Rho.train=ks.matrix(subset(stat.Rho, Set=='train'),'Rho','CDRlbl')
  ks.Rho.test=ks.matrix(subset(stat.Rho, Set=='test'),'Rho','CDRlbl')  
  return(list('Acc'=ks.Acc,'Rho.test'=ks.Rho.test,'Rho.train'=ks.Rho.train))
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

