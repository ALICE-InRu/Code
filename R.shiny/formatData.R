getAttribute<-function(str,regexpr.m,id){
  substr(str,attr(regexpr.m,'capture.start')[,id],attr(regexpr.m,'capture.start')[,id]+attr(regexpr.m,'capture.length')[,id]-1)
}

formatData = function(dat,updateRho=T){

  if(is.null(dat)){return(NULL)}

  cols=colnames(dat)

  #if('PID' %in% cols){ dat$PID <- as.factor(dat$PID) }

  if('Step' %in% cols){
    if(min(dat$Step)==0) { dat$Step=dat$Step+1 } # in order for step to start at 1
    #dat$Step=as.factor(dat$Step)
  }

  if('NumJobs' %in% cols & 'NumMachines' %in% cols) {
    dat$NumJobs <- as.factor(dat$NumJobs)
    dat$NumMachines <- as.factor(dat$NumMachines)
    dat$Dimension <- factor(dat$Dimension, levels = c('30','64','100','144','196'))
    levels(dat$Dimension) = c('6x5','8x8','10x10','12x12','14x14')
  } else  if ('Dimension' %in% cols) {
    dat$Dimension <- factor(dat$Dimension, levels = c('6x5','8x8','10x10','12x12','14x14'))
  }
  if('Shop' %in% cols & 'Distribution' %in% cols & !('Problem' %in% cols)){
    dat$Shop=factor(dat$Shop,levels=c('j','f'))
    dat$Distribution=factor(dat$Distribution, levels=c('rnd','rndn','rnd_p1mdoubled','rnd_pj1doubled','jc','mc','mxc'))
    dat$Problem = interaction(dat$Shop, dat$Distribution)
    levels(dat$Distribution)=c('random','random narrow','random with job variation','random with machine variation','job correlated','machine correlated','mixed correlated')
  }

  if('Problem' %in% colnames(dat)){
    dat$Problem=factor(dat$Problem, levels=c('j.rnd','j.rndn','j.rnd_p1mdoubled','j.rnd_pj1doubled','f.rnd','f.rndn','f.jc','f.mc','f.mxc'))
    levels(dat$Problem)=c('j.rnd','j.rndn','j.rnd, J1','j.rnd, M1','f.rnd','f.rndn','f.jc','f.mc','f.mxc')
  }
  if('SDR' %in% cols){ dat$SDR=factor(dat$SDR,levels=sdrs) }
  if('Track' %in% cols){
    dat$Extended=grepl('EXT',dat$Track)
    if(!updateRho){
      ix=dat$Extended
      dat$PID[ix] = dat$PID[ix]-min(dat$PID[ix])+1
    }

    ix=dat$Track=='OPTEXT'
    if(any(ix)){dat$Track[ix]='OPT'}

    if (any(grepl('SUP',dat$Track))){
      if(!('Supervision' %in% cols)){
        dat$Supervision=ifelse(grepl('UNSUP',dat$Track),'Unsupervised',ifelse(grepl('FIX',dat$Track),'Fixed','Decreasing'))
        dat$Supervision=as.factor(dat$Supervision)
      }

      m=regexpr('IL(?<Iter>[0-9]+)',dat$Track,perl=T)
      dat$Iter=as.numeric(getAttribute(dat$Track,m,1));
      ix=!is.na(dat$Iter)
      dat$Track[ix]=paste('IL',dat$Iter[ix],sep='')
      dat$Iter[is.na(dat$Iter)]=0
      ils=paste('IL',1:max(dat$Iter),sep='')
      dat$Track=factor(dat$Track, levels=c(sdrs,'OPT','RND','ALL',ils))
    } else {
      dat$Track=factor(dat$Track, levels=c(sdrs,'OPT','RND','ALL'))
      dat$Supervision=ifelse(grepl('OPT',dat$Track),'Supervised','Unsupervised')
      dat$Iter=0
    }
  }
  if('Set' %in% cols) { dat$Set=factor(dat$Set,levels=c('train','test')) }

  if('Followed' %in% cols){ dat$Followed = as.logical(dat$Followed) }
  if('phi.RND' %in% cols){

    if(F){
      library('plyr')
      N=100; # rollouts
      rndFeat=interaction('RND',1:N)
      RND <- colsplit(dat$phi.RND,split=';',names=rndFeat)
      RND$Name <- dat$Name
      mRND=melt(RND,measure.vars=rndFeat)

      RND.stats = ddply(mRND,~Name, summarise, phi.RND.mean = mean(value), phi.RND.sd=sd(value), phi.RND.min = min(value), phi.RND.max = max(value))
      dat<-cbind(dat, RND.stats[1:nrow(dat),2:ncol(RND.stats)])
    }
    dat$phi.RND = NULL
  }
  if ('phi.slotCreated' %in% cols){ dat$phi.slotCreated = as.logical(dat$phi.slotCreated) }

  if('Rank' %in% cols){ dat$Rank = as.factor(dat$Rank)}

  if('Scaled' %in% cols){ dat$Scaled <- as.factor(dat$Scaled)}
  if('NrFeat' %in% cols){ dat$NrFeat <- as.factor(dat$NrFeat)}
  if('Prob' %in% cols){ dat$Prob <- factor(dat$Prob, levels=c('equal','opt','bcs','wcs','dbl1st','dbl2nd'))}
  if('TimeIndependent' %in% cols) { dat$TimeIndependent = factor(as.logical(dat$TimeIndependent),levels=c(F,T))}
  if(all(c('Prob','TimeIndependent') %in% cols)) {
    levels(dat$TimeIndependent)=c('TD','TI')
    dat$Problbl = factor(interaction(dat$Prob,dat$TimeIndependent));
    levels(dat$TimeIndependent)=c(F,T)
  }
  if('Model' %in% cols){ dat$Model <- as.factor(dat$Model)}

  if(all(c('Problem','Dimension','Set','PID') %in% colnames(dat))){

    if(!any(dat$Extended)){
      dat=subset(dat,!(Dimension=='10x10' & Set=='test'))
      ix=dat$Dimension=='10x10'
      if(any(ix)){
        Ntrain10x10=300
        #print('Updating sets for 10x10 data')
        dat$Set[ix]=ifelse(dat$PID[ix]<=Ntrain10x10,'train','test')
      }
      Ntrain6x5=500
      dat=subset(dat,!(Dimension=='6x5' & Set=='train' & PID>Ntrain6x5))
    }
    dat$Name = interaction(dat$Problem,dat$Dimension,dat$Set,dat$PID)
  }

  if(updateRho){
    if('Makespan' %in% colnames(dat)){
      dat <- join(dat,dataset.OPT[,c('Name','Optimum')],by='Name',type='inner')
      dat$Rho =  (dat$Makespan-dat$Optimum)/dat$Optimum*100
    } else if('ResultingOptMakespan' %in% colnames(dat)){
      dat <- join(dat,dataset.OPT[,c('Name','Optimum')],by='Name',type='inner')
      dat$Rho = (dat$ResultingOptMakespan-dat$Optimum)/dat$Optimum*100
    }
  }

  # make isMWR etc. logical
  # dat$isSDR=(dat$isMWR | dat$isLWR | dat$isLPT | dat$isSPT)

  areSDRs = grep('sdr.[A-Z]',cols)
  if(length(areSDRs)>0){
    dat$isSDR=F
    for (col in areSDRs){
      dat[,col]=as.logical(dat[,col])
      dat$isSDR = dat$isSDR | dat[,col]
    }
    if('Rho' %in% colnames(dat)){ dat$isOPT=dat$Rho==0 } else { print('Missing Rho for isOPT')}
  }

  if ('phi.totproc' %in% cols){
    colnames(dat)[grep('phi.totproc',colnames(dat))]='phi.totProc'
  } else if ('totproc' %in% cols){
    colnames(dat)[grep('totproc',colnames(dat))]='totProc'
  }
  if ('phi.macfree' %in% cols){
    colnames(dat)[grep('phi.macfree',colnames(dat))]='phi.macFree'
  } else if ('macfree' %in% cols){
    colnames(dat)[grep('macfree',colnames(dat))]='macFree'
  }
  cols=colnames(dat)
  if('Feature' %in% cols){

    if(length(grep('phi',dat$Feature))>0){dat$Feature=substr(dat$Feature,5,100)} # remove 'phi.' from variable name (cleaner)

    if('macfree' %in% unique(dat$Feature)){
      was=c('proc','startTime','endTime','arrivalTime','totproc','wait','wrmJob','jobOps','mac','macfree','wrmMac','macOps','slotReduced','slots','slotsTotal','makespan','wrmTotal','step',sdrs,'RNDmean','RNDstd','RNDmin','RNDmax')
    } else {
      was=c('proc','startTime','endTime','arrivalTime','totProc','wait','wrmJob','jobOps','mac','macFree','wrmMac','macOps','slotReduced','slots','slotsTotal','makespan','wrmTotal','step',sdrs,'RNDmean','RNDstd','RNDmin','RNDmax')
    }

    now=c('proc','startTime','endTime','arrival','totalProc','wait','wrmJob','jobOps','mac','macFree','wrmMac','macOps','slotReduced','slots','slotsTotal','makespan','wrmTotal','step',sdrs,'RND.mean','RND.std','RND.min','RND.max')

    if(all(now %in% levels(dat$Feature))){
      dat$Feature=factor(dat$Feature, levels = now)
    } else {    dat$Feature=factor(dat$Feature, labels = now, levels = was)}

    dat$Featurelbl=dat$Feature;
    #facet_grid compatible
    #levels(dat$Featurelbl)=paste('expression(phi[',1:length(levels(dat$Featurelbl)),'] * ~ ',levels(dat$Featurelbl),')',sep='')
    #facet_wrap compatible
    levels(dat$Featurelbl)=paste(1:length(levels(dat$Featurelbl)),levels(dat$Featurelbl),sep=') ')


    m=regexpr('(?<Global>[A-Z]{3})',dat$Feature,perl=T)
    dat$FeatureType=factor(ifelse(attr(m,'capture.start')!=-1,'Global','Local'),levels=c('Local','Global'))
  }

  if(all(c('NrFeat','Model','Prob') %in% cols)){
    dat$CDR = interaction(dat$NrFeat,dat$Model,dat$Prob)
    dat$CDRlbl = interaction(dat$NrFeat,dat$Model)
    if(length(unique(dat$Prob))>1){ dat$CDRlbl=dat$CDR }
  }

  return(droplevels(dat))
}

feature_gridlabeller <- function(variable, value){

  f_names <- list('proc' = expression(phi[1]*~' proc'),
                  'startTime' = expression(phi[2]*~' startTime'),
                  'endTime' = expression(phi[3]*~' endTime'),
                  'arrival' = expression(phi[4]*~' arrival'),
                  'totalProc' = expression(phi[5]*~' totalProc'),
                  'wait' = expression(phi[6]*~' wait'),
                  'wrmJob' = expression(phi[7]*~' wrmJob'),
                  'jobOps' = expression(phi[8]*~' jobOps'),
                  'mac' = expression(phi[9]*~' mac'),
                  'macFree' = expression(phi[10]*~' macFree'),
                  'wrmMac' = expression(phi[11]*~' wrmMac'),
                  'macOps' = expression(phi[12]*~' macOps'),
                  'slotReduced' = expression(phi[13]*~' slotReduced'),
                  'slots' = expression(phi[14]*~' slots'),
                  'slotsTotal' = expression(phi[15]*~' slotsTotal'),
                  'makespan' = expression(phi[16]*~' makespan'),
                  'wrmTotal' = expression(phi[17]*~' wrmTotal'),
                  'step' = expression(phi[18]*~' step'),
                  'SPT' = expression(phi[19]*~' SPT'),
                  'LPT' = expression(phi[20]*~' LPT'),
                  'LWR' = expression(phi[21]*~' LWR'),
                  'MWR' = expression(phi[22]*~' MWR'),
                  'RND.mean' = expression(phi[23]*~' RND.mean'),
                  'RND.std' = expression(phi[24]*~' RND.std'),
                  'RND.min' = expression(phi[25]*~' RND.min'),
                  'RND.max' = expression(phi[26]*~' RND.max'))

  return(f_names[value])
}
