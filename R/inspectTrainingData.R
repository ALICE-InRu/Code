difficulty.wrt.features = function(problem,dim,quartiles,track='ALL'){
  
  source('Kolmogorov-SmirnovMatrixStepwise.R')
  source('CorrelationMatrixStepwise.R')      
  
  figCor=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'trdat',track,'corrmatrix',extension,sep='.')
  figKS=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'trdat',track,'KSmatrix',extension,sep='.')
  figDiff=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'trdat',track,'difficulty',extension,sep='.')
  
  if(!redoPlot){ if(file.exists(figCor)& file.exists(figKS)& file.exists(figDiff)){return(NULL)}  }
  
  pat=ifelse(track=='ALL',paste(problem,dim,sep='.'),paste(problem,dim,track,sep='.'));
  print(paste('pattern',pat))
  
  dat <- getfilesTraining(pat,Global = T,useDiff = F)  
  feat<-grep('phi.',colnames(dat))  
  
  Q1 = quartiles[interaction(problem,dim),'Q1']
  Q3 = quartiles[interaction(problem,dim),'Q3']
  
  dat$Difficulty=ifelse(dat$Rho==0,'Optimal',ifelse(dat$Rho<Q1,'Easy',ifelse(dat$Rho>Q3,'Hard','Medium')))
  dat$Difficulty = factor(dat$Difficulty,levels=c('Optimal','Easy','Medium','Hard'))
      
  pctEasy=round(summary(dat$Difficulty)['Easy']/nrow(dat)*100,digit=2)
  lblEasy=paste('Easy ','(Q1=',quartiles[interaction(problem,dim),'Q1'],', ',pctEasy,'%)',sep='')
  pctHard=round(summary(dat$Difficulty)['Hard']/nrow(dat)*100,digit=2)
  lblHard=paste('Hard ','(Q3=',quartiles[interaction(problem,dim),'Q3'],', ',pctHard,'%)',sep='')

  dat=subset(dat,Step<max(dat$Step)) # last step has no choice to learn
  
  p=ggplot(dat,aes(x=Step,fill=Difficulty))+geom_bar(binwidth=1, position='fill')+
    ggplotFill('Difficulty',num = length(levels(dat$Difficulty)))+
    ggplotCommon(dat,ylabel = 'Proportionality of training data', probability = T)
  
  if(track=='ALL'){
    allx <- rbind(dat,transform(dat,Track="ALL"))
    p=p %+% allx+ facet_wrap(~Track,ncol=4)+
      theme(legend.justification=c(1,0), legend.position=c(1,0))        
  } 
  
  if(!file.exists(figDiff)|redoPlot){ ggsave(p,filename=figDiff,height = Height.half,width = Width,units=units,dpi=dpi) }
  
  featDat=dat[,c(colnames(dat)[feat],'Step','Difficulty','Rho')]
  ylabel=sprintf('%s (%.2f%%) vs. %s (%.2f%%)','Easy',pctEasy,'Hard',pctHard)
  ks=ks.matrix.stepwise(subset(featDat,Difficulty!='Medium')[,-grep('Rho',colnames(featDat))],'Difficulty')    
  if(!is.null(ks)){
    p=plot.ks.matrix.stepwise(ks,ylabel)  
    if(!file.exists(figKS)|redoPlot){ ggsave(p,filename=figKS,width=Height.full,height=Width,units=units,dpi=dpi) }
    
    cols=grep('Difficulty',colnames(featDat),invert=T);    
    cor.mat.easy=correlation.matrix.stepwise(featDat[featDat$Difficulty %in% 'Easy',cols],'Rho')
    cor.mat.hard=correlation.matrix.stepwise(featDat[featDat$Difficulty %in% 'Hard',cols],'Rho')  
    
    p=plot.correlation.matrices.stepwise(cor.mat.easy,lblEasy,cor.mat.hard,lblHard)
    
    if(!file.exists(figCor)|redoPlot){ ggsave(p,filename=figCor,height=Width,width=Height.full,units=units,dpi=dpi)}
    
  } else print(paste(ylabel,'cannot compare',sep=' -- '))  
}
