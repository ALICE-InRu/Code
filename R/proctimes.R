proctimes=function(dim, quartiles, SDR){
  
  source('Kolmogorov-SmirnovMatrix.R')
  
  inspect<-function(dat){
    firstJob=grep('^J[0-9]',colnames(dat))[1]
    lastJob=rev(grep('^J[0-9]',colnames(dat)))[1]
    firstMac=grep('^M[0-9]',colnames(dat))[1]
    lastMac=rev(grep('^M[0-9]',colnames(dat)))[1]
    
    dat$Jdiff <- dat[,lastJob]-dat[,firstJob]
    dat$Mdiff <- dat[,lastMac]-dat[,firstMac]
    
    dimension=unique(dat$Dimension)
    
    dat <- ddply(dat,~Problem+Dimension, mutate, Difficulty=ifelse(Rho<quartiles[interaction(Problem,Dimension),'Q1'],'Easy',ifelse(Rho>quartiles[interaction(Problem,Dimension),'Q3'],'Hard','Medium')))    
    dat$Difficulty = factor(dat$Difficulty,levels=c('Easy','Medium','Hard'))
    
    for(problem in unique(dat$Problem)){    
      pdat <- subset(dat,Problem==problem)
      for(sdr in unique(dat$SDR)){
        sdat <- subset(pdat,SDR==sdr)  
        sdat = subset(sdat,Difficulty!='Medium')[,colnames(pdat)[grep('^J[0-9]|^M[0-9]|Jdiff|Mdiff|Difficulty',colnames(pdat))]]
        
        ks.mat=ks.matrix(sdat,'Difficulty')      
        if(!is.null(ks.mat)){
          lbls=ddply(sdat,~Difficulty,summarise,cnt=length(Difficulty));        
          p=plot.ks.matrix(ks.mat, lbls)                
          ggsave(p,filename=paste(paste(subdir,problem,'procs',sep='/'),'KSmatrix',dim,sdr,extension,sep='.'),width=WidthMM,height=HeightMM.half,units=units,dpi=dpi)   
        }  
      }    
    }
  }
  
  procs=getfiles('../MATLAB/proctimes/',paste(dim,'.csv',sep=''))
  procs <- subset(procs, Name %in% SDR$Name)
  procs <- join(SDR,procs,by=colnames(SDR)[colnames(SDR) %in% colnames(procs)],type='inner'); 
  
  inspect(procs)  
  
}
