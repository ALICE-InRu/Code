findStepwiseCDRoptimality <- function(model){

  m=regexpr('exhaust.(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9]+x[0-9]+).(?<Rank>[a-z]).(?<Track>[A-Z]+)',model,perl=T)
  problem=getAttribute(model,m,1)
  dim=getAttribute(model,m,2)
  rank=getAttribute(model,m,3)
  track=getAttribute(model,m,4)  
  
  fname=paste('../liblinear',dim,'optStepwiseAcc',model,sep='/') 
  if(file.exists(fname)){ opt.acc=read.csv(fname)}else{
    print(fname)
    weights=getWeights(model,T,T)
    trdat=getfilesTraining(pattern = paste(problem,dim,track,sep='.'), rank = rank, Global = F, useDiff = F)
    trdat$isOPT=trdat$Rho==0
    trdat=subset(trdat,Set=='train')    
    Ntrain=quantile(unique(trdat$PID),0.8)
    trdat=subset(trdat,PID>Ntrain) # only do this for validation set
    trdat=trdat[,grep('phi|PID|Step|isOPT',colnames(trdat))]    
    phis=colnames(weights)    
    trdat=cbind(trdat[,c('Step','PID','isOPT')],as.matrix(trdat[,phis]) %*% t(weights))
    trdat=melt(trdat,id.vars = colnames(trdat)[grep('^F[0-9]+',colnames(trdat),invert = T)])
    mdat=NULL
    for(var in unique(trdat$variable)){ print(var)
      tmp=ddply(subset(trdat,variable==var),~PID+Step+variable,mutate,isMax=value==max(value),.progress = 'text')
      tmp=subset(tmp,isMax==T)
      tmp=ddply(tmp,~Step+variable,summarise,Validation.Accuracy=mean(isOPT),.progress = 'text')  
      mdat=rbind(mdat,tmp)                    
    }
    opt.acc=dcast(mdat,variable~Step,value.var='Validation.Accuracy')
    steps=2:ncol(opt.acc)
    colnames(opt.acc)[steps]=paste('Step',colnames(opt.acc)[steps],sep='.')
    opt.acc[,steps]=round(opt.acc[,steps],digit=2)
    write.csv(opt.acc,file=fname,row.names=F,quote=F)    
  }
  return(opt.acc)
}

