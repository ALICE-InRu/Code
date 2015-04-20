library('plyr') # for merging data frames
source('getfiles.R')

# Remove duplicates warn about problem instances that are not optimal ------------------
joinOptDirectories <- function(){
  files=list.files('../OPT/',pattern='opt.*.csv')
  for (file in files){
    print(file)
    mat=read.csv(paste('../MATLAB/opt/',file,sep=''))
    mat=subset(mat,Solved=='opt') # only take optimum values
    main=read.csv(paste('../OPT/',file,sep=''))
    dat=merge(main,mat,by=colnames(main)[grep('Simplex',colnames(main),invert=T)],all=T)
    
    if(nrow(dat)>nrow(main)){
      
      dat$Simplex.x=as.numeric(dat$Simplex.x)
      dat$Simplex.y=as.numeric(dat$Simplex.y)
      
      dat$Simplex.x[is.na(dat$Simplex.x)]=-1
      dat$Simplex.y[is.na(dat$Simplex.y)]=-1

      dat$Simplex=ifelse(dat$Simplex.x<0,dat$Simplex.y,ifelse(dat$Simplex.y<0,dat$Simplex.x,min(dat$Simplex.x,dat$Simplex.y)))
            
      dat$Simplex.x=NULL
      dat$Simplex.y=NULL
      
      write.csv(dat,file=paste('../OPT/',file,sep=''),row.names=F,quote=F)  
      print(paste('Had to rewrite',file,'due to new optimum'))            
    } 
  }  
}


removeOptimumDuplicates <- function(){
  for (file in list.files('../OPT',pattern='.csv', full.names=T)){
    dat <- read.csv(file)
    dup=duplicated(dat)
  
    
    if(sum(dup)>0){
      dat=dat[!dup,]
      write.csv(dat,file=file,row.names=F,quote=F)  
      print(paste('Had to rewrite',file,'due duplicate entries'))
    } else if(any(dat$Solved!='opt')) {
      numSub=sum(dat$Solved!='opt')
      if(numSub>2){
        dat=subset(dat,Solved=='opt')
        write.csv(dat,file=file,row.names=F,quote=F)  
        print(paste('Had to rewrite',file,'best known solution'))                                                      
      } else {  
        print(paste(file,'has',numSub,'best known solutions'))  
      }
      
    } 
    
    idx=with(dat, order(Set, NumJobs, NumMachines, PID))
    if(any(idx!=1:nrow(dat))){
      dat=dat[idx,]
      write.csv(dat,file=file,row.names=F,quote=F)  
      print(paste('Had to rewrite',file,'due to ordering'))      
    }
  }  
}


# Make sure rho values are up to date ------------------------------------------------
findRho <- function(Makespan,Optimum){  return(round((100*(Makespan-Optimum)/Optimum),digits=3)) }


updateRhosForSDRs <- function(){
  OPT=getOPTs();
  
  for (file in list.files('../SDR',pattern='*.csv',full.names=T)){
    dat <- read.csv(file)    
    dat <- join(dat,OPT,by='Name')
    if(sum(!is.na(dat$Optimum))!=sum(!is.na(dat$Rho))) {      
      print(paste('Had to rewrite',file,'due to missing rho values'))      
      print(summary(dat$Rho))
      dat$Rho=findRho(dat$Makespan,dat$Optimum)      
      print(summary(dat$Rho))
      dat$Optimum=NULL
      write.csv(dat,file=file,quote=F,row.names=F)      
    }
  }
}

trainOptSanityCheck <- function(subdir='../trainingData/',pattern='*.OPT.*.Local.csv|*.OPT.*.Global.csv'){
  for (file in list.files(subdir,pattern=pattern,full.names=T)){
    dat <- read.csv(file)
    fdat=subset(dat,Followed==T)
    if(any(fdat$Rho>0))
    {
      print(paste(file,'contains',sum(fdat$Rho>0),'rho values >0'))            
    }    
  } 
}

trainMalformatted <- function(subdir='../trainingData/',pattern='Local.csv|Global.csv'){
  for (file in list.files(subdir,pattern=pattern,full.names=T)){
    dat <- read.csv(file) 
    if(any(is.na(dat))){
      print(paste(file,'contains nan'))
      #file.remove(file)
    } 
  }
}

trainMissingRankOrRhos <- function(subdir='../trainingData/',pattern='Local.csv|Global.csv'){
  for (file in list.files(subdir,pattern=pattern,full.names=T)){
    dat <- read.csv(file)    
    if(any(is.na(dat$Rho)))
    {
      info=strsplit(file,'trdat.|.csv')[[1]][2]
      info=strsplit(info,"\\.")
      Shop=info[[1]][1]
      Distribution=info[[1]][2]
      
      print(paste(file,'contains',sum(is.na(dat$Rho)),'nan values and ',sum(is.na(dat$Rank)),'rank values'))
      OPT=getOPTs()
      
      dat$Name=interaction(Shop,Distribution,ifelse(max(dat$Step)==29,'6x5','10x10'),'train',dat$PID)
      dat=join(dat,OPT,by='Name',match='first')
      print(summary(dat$Rho))      
      dat$Rho=findRho(dat$ResultingOptMakespan,dat$Optimum)      
      print(summary(dat$Rho))
      dat$Name=NULL
      dat$Optimum=NULL
      print(paste('Had to rewrite',file,'due to missing rho values'))      
      write.csv(dat,file=file,quote=F,row.names=F)            
    } else if(any(dat$Rho<0)) {
      print(paste(file,'contains',sum(dat$Rho<0),'negative rho'))
      if(sum(dat$Rho<0)<10){
        dat=dat[which(dat$Rho>=0),]
        print(paste('Had to rewrite',file,'due to negative rho values'))      
        write.csv(dat,file=file,quote=F,row.names=F)              
      } else { return(summary(dat)) }
    }
  }   
}


if(F){
  createSubFolders <- function(subdir='figures'){
    for(problem in c('j.rnd','j.rndn','j.rnd, J1','j.rnd, M1','f.rnd','f.rndn','f.jc','f.mc','f.mxc')){  
      dir=paste(subdir,problem,sep='/')
      if(length(list.dirs(dir))==0) { dir.create(dir) }
    }    
  }  
}

compareMatlabCsharp <- function(){
  
  if(!file.exists('../trainingData/trdat.j.rnd.10x10.OPT.Local.csv') |
       !file.exists('../trainingData/trdat.j.rnd.10x10.OPT.Local.2.csv') ) ( return(NULL))  
  
  dat.matlab = getfiles(F,F,'../trainingData/trdat.j.rnd.10x10.OPT.Local.2.csv')
  dat.csharp = getfiles(F,F,'../trainingData/trdat.j.rnd.10x10.OPT.Local.csv')
  
  dat.matlab=melt(subset(dat.matlab,Followed==T), id.vars=colnames(dat.matlab)[-grep('phi',colnames(dat.matlab))])
  dat.csharp=melt(subset(dat.csharp,Followed==T), id.vars=colnames(dat.csharp)[-grep('phi',colnames(dat.csharp))])
  
  dat.matlab = ddply(dat.matlab,~Step+variable,summarise,mu=mean(value))
  dat.csharp = ddply(dat.csharp,~Step+variable,summarise,mu=mean(value))
  
  dat.matlab$data='matlab'
  dat.csharp$data='csharp'
  ddply2=rbind(dat.csharp,dat.matlab)
  
  p=ggplot(ddply2,aes(x=as.numeric(Step),y=mu,color=data))+geom_line()+facet_wrap(~variable,scales='free')
  ggsave('matlab_csharp_difference.jpg')
  return(p)
  
}


if(F){
  compareMatlabCsharp()
  removeOptimumDuplicates()
  updateRhosForSDRs()
  trainOptSanityCheck()
  trainMissingRankOrRhos()  
  trainMalformatted()
}

joinOptDirectories()
removeOptimumDuplicates()
updateRhosForSDRs()




















cleanUpTrainingData <- function(){
  files=list.files('../trainingData/','j.rndn.10x10',full.names = T)  
  for(file in files){
    dat=read.csv(file)
    if(any(dat$PID>=266)){
      dat=subset(dat,PID<266)      
      write.csv(dat,file=file,row.names=F,quote=F)
      print(paste('Updated',file))
    }    
  }
}



