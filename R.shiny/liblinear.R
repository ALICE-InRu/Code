library('LiblineaR')

stepwiseProbability <- function(STEP,problem,dimension,probability){
  dim=max(STEP)
  half=round(dim/2,digit=0)
  last=dim-half
  w=switch(probability,
           'linear'=1:max(STEP),
           'opt'=1-findStepwiseOptimality(problem,dimension)$Stats$rnd.mu,
           'bcs'=getBWCaseScenario(paste(problem,dimension,'OPT',sep='.'))$best.mu,
           'wcs'=getBWCaseScenario(paste(problem,dimension,'OPT',sep='.'))$worst.mu,
           'dbl1st'=c(rep(2,half),rep(1,last)),
           'dbl2nd'=c(rep(1,half),rep(2,last)),
           rep(1,max(STEP)))
  w=w/sum(w); # normalize
  return(w[STEP])
}

estimateLiblinearModels <- function(problem,dimension,start,probability,timedependent,tracks,rank){
  ix=grepl('IL',tracks)
  if(any(ix)){ tracks[ix]=paste0(substr(tracks[ix],1,2),'[0-9]+',substr(tracks[ix],3,100)) }
  tracks=paste0('(',paste(tracks,collapse = '|'),')')
  m=list.files('../liblinear/CDR/',
               paste(paste0('^',start),problem,dimension,rank,tracks,probability,"weights",ifelse(timedependent,'timedependent','timeindependent'),sep='.'))
  minNum=ifelse(start=='full',2,697)
  for(model in m){ rho.statistic(model,minNum = minNum) }
  return(paste('Estimate LIBLINEAR models for',length(m),'files'))
}

rho.statistic <- function(model,minNum=697){
  #choose(16,1)+choose(16,2)+choose(16,3)+choose(16,16)==697

  fname=paste('../liblinear/CDR/summary',model,sep='.')
  if(!grepl('.csv',fname)){ fname=paste(fname,'csv',sep='.')}

  if(file.exists(fname)){ rho.stats=read.csv(fname)}
  else{
    files=list.files(paste('..//liblinear/CDR',model,sep='/'))
    print(paste(length(files),'models found for',model))
    if(length(files)<minNum){return(NULL)}

    model.rex="(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9x]+).(?<Rank>[a-z]).(?<Track>[A-Z]{2}[A-Z0-9]+).(?<Probability>[a-z0-9]+).weights.time"
    m=regexpr(model.rex,model,perl=T)
    problem=getAttribute(model,m,1)
    rank=getAttribute(model,m,3)
    track=getAttribute(model,m,4)
    probability=getAttribute(model,m,5)
    timeindependent=grepl('timeindependent$',model)
    print(paste(rank,track,probability,timeindependent))

    ALLDAT=NULL
    name.rex="F(?<NrFeat>[0-9]+).Model(?<Model>[0-9]+)"
    for(file in files){
      dat=read.csv(paste('..//liblinear/CDR',model,file,sep='/'))
      m=regexpr(name.rex,file,perl=T)
      dat$NrFeat <- as.factor(getAttribute(file,m,1))
      dat$Model <- as.factor(getAttribute(file,m,2))
      dat$Heuristic=NULL
      dat$Prob=probability
      ALLDAT=rbind(ALLDAT,dat)
    }
    ALLDAT$Problem=problem
    ALLDAT$TimeIndependent=timeindependent
    dat=formatData(ALLDAT);
    Ntrain=quantile(unique(subset(dat,Set=='train')$PID),.8) # 80% of training data saved for validation
    levels(dat$Set)=c(levels(dat$Set),'validation')
    dat$Set[dat$Set=='train' & dat$PID>Ntrain]='validation' # 20% of training data saved for validation

    rho.stats = ddply(dat,~Problem+NrFeat+Model+Prob+TimeIndependent, summarise,
                      Training.Rho = round(mean(Rho[Set=='train']), digits = 5),
                      NTrain = sum(Set=='train'),
                      Validation.Rho = round(mean(Rho[Set=='validation']), digits = 5),
                      NValidation = sum(Set=='validation'),
                      Test.Rho = round(mean(Rho[Set=='test']), digits = 5),
                      NTest = sum(Set=='test'))

    write.table(rho.stats, file=fname, quote=F,row.names=F,dec='.',sep=',')
  }
  return(rho.stats)
}

getTrainingData <- function(problem,dim,rank,track,scale){

  useDiff=T
  dat <- getTrainingDataRaw(problem,dim,track,rank,useDiff)
  if(is.null(dat)){ return(NULL) }

  if(useDiff) { label = sign(dat$ResultingOptMakespan) } else { label = as.numeric(dat$Rho == 0); }

  features=dat[,grep('phi',colnames(dat))];
  remove=NULL
  for(col in 1:ncol(features)) { if(max(features[,col])==min(features[,col])) { remove = c(remove,col)}}
  if(!is.null(remove)) { features = features[,-remove]}

  if(scale) {
    ## Rescale each column to range between 0 and 1
    features=apply(features, MARGIN = 2, FUN = function(X) 2*(X - min(X))/diff(range(X))-1)
  }

  info = paste('Distribution',problem,'and dimension',dim,'and with',ifelse(useDiff,'preference pairs','direct classification'),'\n------------\n')
  for(lbl in unique(label)){ info=paste(info,paste('Label',lbl,':',sum(label==lbl)),sep='\n') }
  info = paste(info,'Features:',sep='\n')
  info=paste(info, paste(format(str_split_fixed(colnames(features),'phi.',2)[,2], justfy=F),' ',collapse=''), sep='\n')
  print(cat(info))

  return(list(Y=label,X=features,PID=dat$PID,STEP=dat$Step, Dimension=dim,Problem=problem,Info=info))
}

linearWeights <- function(dat,logFile,probability,timedependent,exhaustive,lmax){

  Ntrain=round(quantile(unique(dat$PID),0.8),digit=0) # 20% saved for validation
  print(paste('Ntrain=',Ntrain))
  print(paste('(train=',round(100*mean(unique(dat$PID)<=Ntrain),digit=1),'% validation=',round(100*mean(unique(dat$PID)>Ntrain),digit=1),'%)',sep=''))
  print(paste('(#',length(unique(dat$PID)),' => train=#',sum(unique(dat$PID)<=Ntrain),' validation=#',sum(unique(dat$PID)>Ntrain),')',sep=''))

  liblinearModel <- function(xTrain, yTrain, prob, lmax){
    # Logistic Regression
    t=0

    if(is.null(ncol(xTrain))) { xTrain=cbind(xTrain,rep(0,length(xTrain))) }

    if(is.null(lmax)){lmax=nrow(xTrain)}

    smpl=sample(nrow(xTrain), lmax, replace=T, prob=prob)

    xTrain=xTrain[smpl,]
    yTrain=yTrain[smpl]

    # Train PREF model
    model = LiblineaR(xTrain,yTrain, type=t, cost=1, epsilon = 0.005, bias = F)
    return(model)
  }

  liblinearPrediction <- function(model,X,Y,STEP){
    # Make prediction
    df=data.frame(Feat=X,Step=STEP,Pred=rep(NA,length(Y)),True=Y)

    if(timedependent){
      for(step in 1:length(model)){
        if(!is.null(model[[step]])){
          ix=STEP %in% step
          df$Pred[ix]=predict(model[[step]],X[ix,])$predictions
        }
      }
    } else { df$Pred=predict(model,X)$predictions }

    acc.mu=mean(df$Pred == df$True, na.rm = T)*100
    acc.stepwise=ddply(df,~Step,summarise,mu=mean(Pred==True)*100)$mu

    return(list(mu=acc.mu,stepwise=acc.stepwise))
  }

  full.model <- function(dat,phiCol){

    stepwiseLiblinearModel <- function(xTrain,yTrain,prob,STEP){
      m=list()
      for(step in unique(STEP)){
        ix = STEP==step
        m[[step]]=liblinearModel(xTrain[ix,],yTrain[ix],prob[ix],lmax)
      }
      return(m)
    }

    train = dat$PID <= Ntrain

    if(timedependent){
      model=stepwiseLiblinearModel(dat$X[train,phiCol], dat$Y[train], dat$Probability[train], dat$STEP[train])
      Weights=matrix(0,ncol=length(model[[1]]$W),nrow=max(dat$STEP))
      for(step in 1:length(model)){
        if(!is.null(model[[step]])) {
          Weights[step,]=model[[step]]$W*model[[step]]$ClassNames[1]*-1 # assume max
        }
      }
      Weight=data.frame(Weights);
      rownames(Weight)=1:nrow(Weights)
      colnames(Weight)=colnames(dat$X)[phiCol]
    } else {
      model = liblinearModel(dat$X[train,phiCol], dat$Y[train], dat$Probability[train],lmax)
      Weight=model$W*model$ClassNames[1]*-1 # assume max
    }
    validation.acc = liblinearPrediction(model, dat$X[!train,phiCol], dat$Y[!train], dat$STEP[!train])
    training.acc = liblinearPrediction(model, dat$X[train,phiCol], dat$Y[train], dat$STEP[train])
    return(list(Weight=Weight,validation.acc=validation.acc,training.acc=training.acc))
  }

  addModelInfo <- function(combo,r,m){
    combo$Info[r,'validation.acc.mu']=m$validation.acc$mu
    combo$Info[r,'training.acc.mu']=m$training.acc$mu
    combo$Model[r] = list(m$Weight)
    combo$stepwise.training.acc[r]=list(m$training.acc$stepwise)
    combo$stepwise.validation.acc[r]=list(m$validation.acc$stepwise)
    return(combo)
  }

  logExhaustive <- function(results,nrFeat){

    Model=results$Model
    Info=results$Info
    stepwise.training.acc = results$stepwise.training.acc
    stepwise.validation.acc = results$stepwise.validation.acc
    nrSteps=length(stepwise.training.acc[1][[1]])

    print(paste('Max acc. for',nrFeat,'features:',round(max(Info$training.acc.mu),2)))

    if(!file.exists(logFile)){ # create header
      cat('Type','NrFeat','Model','Feature','mean',paste('Step',1:nrSteps,sep='.'),sep=',', file = logFile, append = F)
    }

    for(N in 1:nrow(Info)){
      for(col in 1:nrFeat){
        W=Model[N][[1]][,col];
        cat('\nWeight',nrFeat,N,colnames(Model[N][[1]])[col],NA,W,sep=',', file = logFile, append = T)
      }
      cat('\nTraining.Accuracy',nrFeat,N,NA,
          round(mean(stepwise.training.acc[N][[1]]),digits = 2),
          round(stepwise.training.acc[N][[1]],digits = 2),
          sep=',', file = logFile, append = T)
      cat('\nValidation.Accuracy',nrFeat,N,NA,
          round(mean(stepwise.validation.acc[N][[1]],digits = 2)),
          round(stepwise.validation.acc[N][[1]],digits = 2),sep=',', file = logFile, append = T)
    }
  }

  dat$Probability = stepwiseProbability(dat$STEP, problem, dat$Dimension[1], probability)
  phiCol = grep('phi',colnames(dat$X));

  # use all features
  combo=list(Info=data.frame(rbind(phiCol),validation.acc.mu=NA,training.acc.mu=NA,row.names=1))
  m = full.model(dat,phiCol)
  combo=addModelInfo(combo,1,m)
  allResults = list(FeatureAll=combo)
  logExhaustive(allResults$FeatureAll,length(phiCol))

  if(!exhaustive){return(allResults)}

  # use only one feature
  combo=list(Info=data.frame('X1'=phiCol,validation.acc.mu=NA,training.acc.mu=NA))
  rownames(combo$Info)=c(1:nrow(combo$Info))
  for(r in phiCol){
    m=full.model(dat,c(r,r))
    combo=addModelInfo(combo,r,m)
  }
  allResults = append(allResults,list(Feature1=combo))
  logExhaustive(allResults$Feature1,1)

  # use only two features
  combo = list(Info=expand.grid(X1 = phiCol, X2 = phiCol, validation.acc.mu=NA,training.acc.mu=NA))
  combo$Info = combo$Info[combo$Info$X1 < combo$Info$X2,]
  rownames(combo$Info)=c(1:nrow(combo$Info))
  for(r in 1:nrow(combo$Info)){
    m=full.model(dat,as.numeric(combo$Info[r,1:2]))
    combo=addModelInfo(combo,r,m)
  }
  allResults = append(allResults,list(Feature2=combo))
  logExhaustive(allResults$Feature2,2)

  # use only three features
  combo = list(Info=expand.grid(X1 = phiCol, X2 = phiCol, X3=phiCol, validation.acc.mu = 0, training.acc.mu = 0))
  combo$Info = combo$Info[combo$Info$X1 < combo$Info$X2 & combo$Info$X2<combo$Info$X3,]
  rownames(combo$Info)=c(1:nrow(combo$Info))
  for(r in 1:nrow(combo$Info)){
    m=full.model(dat,as.numeric(combo$Info[r,1:3]))
    combo=addModelInfo(combo,r,m)
  }
  allResults = append(allResults,list(Feature3=combo))
  logExhaustive(allResults$Feature3,3)
  return(allResults)

}

getWeights <- function(model,timedependent,asMatrix=F){
  m=regexpr(".(?<Dimension>[0-9]+x[0-9]+).",model,perl=T)
  dim=getAttribute(model,m,1)
  weights=read.csv(paste('../liblinear/',dim,'/',model,sep=''))
  weights=subset(weights,Type=='Weight')
  if(!timedependent){ weights=weights[,c(1:4,6)] } else { weights$mean=NULL };
  if(asMatrix){
    weights$CDR=interaction(paste('F',weights$NrFeat,sep=''),paste('M',weights$Model,sep=''))
    weights=dcast(weights,CDR~Feature,value.var = 'Step.1', fill = 0);
    wmat=as.matrix(weights[,2:ncol(weights)])
    rownames(wmat)=weights$CDR
    return(wmat)
  }
  return(formatData(weights))
}

liblinearBoxplot <- function(CDR,SDR=NULL,ColorVar,xVar='CDRlbl',xText='CDR',tiltText=T,lineTypeVar=NA){

  colnames(CDR)[grep(ColorVar,colnames(CDR))]='ColorVar'
  colnames(CDR)[grep(xVar,colnames(CDR))]='xVar'

  if(!is.na(lineTypeVar))
    colnames(CDR)[grep(lineTypeVar,colnames(CDR))]='lineTypeVar'

  if(!is.null(SDR)){
    SDR <- subset(SDR,Name %in% CDR$Name)
    SDR$xVar=SDR$SDR
    #print(ddply(SDR,~Problem+Dimension+Set+SDR,summarise,Rho.mu=mean(Rho),Rho.sd=sd(Rho)))
  }
  #print(ddply(CDR,~Problem+Dimension+Set+Prob+Best+NrFeat+Model,summarise,Rho.mu=mean(Rho),Rho.sd=sd(Rho)))
  p=ggplot(CDR,aes(x=as.factor(xVar),y=Rho))

  if(!is.na(lineTypeVar))
    p=p+geom_boxplot(aes(color=ColorVar,linetype=lineTypeVar))+scale_linetype(lineTypeVar)
  else
    p=p+geom_boxplot(aes(color=ColorVar))

  if(!is.null(SDR)){ p=p+geom_boxplot(data=SDR,aes(fill=SDR))+ggplotFill('SDR',4);}
  p=p+facet_grid(Set~Problem,scale='free_x') +
    ggplotColor(xText,length(unique(CDR$ColorVar))) +
    xlab('')+ylab(rhoLabel)

  if(tiltText){ p=p+theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) }
  return(p)
}

createLiblinearModel <- function(problem,dimension,track,rank,probability,timedependent,exhaustive,lmax,scale=F){
  if(substr(track,1,2)=='IL')
  {
    supstr=substr(track,3,100)
    track=paste0('IL',length(list.files(path = '../trainingData',paste('trdat',problem,dimension,paste0('IL[0-9]+',supstr),'Local','diff',rank,'csv',sep='.'))),supstr)
  }

  fileName <- logFile(problem,dimension,rank,track,probability,exhaustive,timedependent,scale)
  if(file.exists(fileName)|(!exhaustive & file.exists(logFile(problem,dimension,rank,track,probability,T,timedependent,scale)))){
    return(paste('Logfile',fileName,'already exists.'))
  }
  print(fileName)

  dat = getTrainingData(problem,dimension,rank,track,scale)
  if(is.null(dat)){return('Data is null! Check if trainingdata exists for chosen trajectory.')}

  allResults=linearWeights(dat,fileName,probability,timedependent,exhaustive,lmax)
  return(paste('Trained on',round(100*lmax/nrow(dat$X)),'% of the total preference set'))
}

logFile <- function(problem,dimension,rank,track,probability,exhaustive,timedependent,scale){
  liblinearDir=paste('../liblinear/',dimension,'/',sep='')
  dir.create(path = liblinearDir,showWarnings = FALSE)

  file = paste(problem,dimension,rank,track,probability,'weights',
                  ifelse(timedependent,'timedependent','timeindependent'),'csv',sep='.')
  if(scale){file=paste('sc',file,sep='.')}
  file = paste(liblinearDir,ifelse(exhaustive,'exhaust.','full.'),file,sep='')
  return(file)
}

getPrefInfo <- function(logFile,Set='Validation'){
  rho.stats = rho.statistic(logFile)
  if(is.null(rho.stats)){return(NULL)}
  rho.stats = rho.stats[,c('Problem','NrFeat','Model','Prob',paste(Set,'Rho',sep='.'),'NValidation')]

  acc.pref = getPrefSetAccuracy(logFile,paste(Set,'Accuracy',sep='.'),onlyMean = T)
  if(is.null(acc.pref)){return(NULL)}

  pref=join(rho.stats, acc.pref, by = c('NrFeat','Model'))

  # Make a distinction between mean cross-validation accuracy and stepwise training accuracy
  acc.opt = getOptimaltyAccuracy(logFile,T)
  if(is.null(acc.opt)){return(NULL)}
  acc.opt=acc.opt[,c('NrFeat','Model',paste(Set,'Accuracy',sep='.'))]
  pref=merge(pref, acc.opt, by = c('NrFeat','Model'),suffixes = c('.Classification','.Optimality'))

  pref=pareto.ranking(pref,paste(Set,'Accuracy.Optimality',sep='.'))$Ranked
  pref=formatData(pref)
  pref$File=logFile
  return(pref)
}

getOptimaltyAccuracy <- function(model,reportMean=T){
  m=regexpr(".(?<Dimension>[0-9]+x[0-9]+).",model,perl=T)
  dim=getAttribute(model,m,1)
  fname=paste('../liblinear',dim,'optStepwiseAcc',model,sep='/')
  if(!file.exists(fname)){ return(NULL)}
  acc = read.csv(fname)
  if(!grepl(fname,'MATLAB')){
    tmp=str_split_fixed(gsub('[.]','_',acc$variable),pat='_',n=2)
    acc$variable=NULL
    acc$NrFeat=as.numeric(substr(tmp[,1],2,100))
    acc$Model=as.numeric(substr(tmp[,2],2,100))
    acc=melt(acc,id.vars = c('NrFeat','Model'), variable.name = 'Step', value.name = 'validation.isOptimal')
    acc$Step=as.numeric(substr(acc$Step,6,100))
    acc$test.isOptimal=NA
    acc$train.isOptimal=NA
  }

  if(reportMean){
    # summarise over all steps
    stats <- ddply(acc, ~NrFeat+Model, summarise,
                   Training.Accuracy=mean(train.isOptimal)*100,
                   Validation.Accuracy=mean(validation.isOptimal)*100,
                   Testing.Accuracy=mean(test.isOptimal)*100)
    return(stats)
  }
  return(acc)
}

getPrefSetAccuracy <- function(model,type=NULL,onlyMean=F){
  m=regexpr(".(?<Dimension>[0-9]+x[0-9]+).",model,perl=T)
  dim=getAttribute(model,m,1)
  acc=read.csv(paste('../liblinear/',dim,'/',model,sep=''))
  acc=subset(acc,Type!='Weight'); acc$Feature=NULL
  if(!is.null(type)){ acc = subset(acc,Type==type)}

  acc=melt(acc,id.vars = grep('Step',colnames(acc),invert = T), variable.name = 'Step')
  acc$Step=as.numeric(substr(acc$Step,6,100))

  if(onlyMean){
    #acc=acc[,grep('Step',colnames(acc),invert=T)]
    acc=ddply(acc,~Type+NrFeat+Model,summarise,mean=mean(value,na.rm = T))
    acc=dcast(acc,NrFeat+Model~Type,value.var = 'mean')
  } else {
    acc$value=acc$value/100
  }
  return(acc)
}

pareto.ranking <- function(weights,byVar){

  weights=arrange(weights, desc(weights[,byVar]), weights$Validation.Rho)
  weights$Pareto.front=F
  weights[which(!duplicated(cummin(weights$Validation.Rho))),'Pareto.front']=T

  front=subset(weights,Pareto.front==T)
  front=front[order(front$Validation.Rho),]

  return(list(Front=front,Ranked=weights))
}

pareto.ranking.wrtNrFeat <- function(pref){
  pfront=NULL
  for(nrFeat in unique(pref$NrFeat)){
    pdat=subset(pref,NrFeat==nrFeat)
    front=pareto.ranking(pdat,'Validation.Accuracy.Optimality')$Front
    pfront=rbind(pfront,front)
  }
  pfront=pareto.ranking(pfront,'Validation.Accuracy.Optimality')$Ranked
  return(pfront)
}

liblinearXtable = function(dat.fronts,onlyPareto=F){
  if(is.null(dat.fronts)){return(NULL)}
  if(onlyPareto){dat.fronts=subset(dat.fronts,Pareto.front==T)}
  library('xtable')
  tmp=ddply(dat.fronts,~Problem+NrFeat+Model+Prob,summarise,
            Accuracy.Optimality=round(Validation.Accuracy.Optimality,digit=2),
            Accuracy.Classification=round(Validation.Accuracy.Classification,digit=2),
            Rho=round(Validation.Rho,digit=2),
            Pareto=Pareto.front)
  #sort
  tmp=tmp[order(tmp$Problem,tmp$Rho,-tmp$Accuracy.Optimality,-tmp$Accuracy.Classification),];
  tmp$Pareto=factor(tmp$Pareto, levels=c(T,F), labels=c('$\\blacktriangle$',''))
  return(xtable(tmp))#,include.rownames=FALSE,sanitize.text.function=function(x){x})
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

liblinearKolmogorov <- function(dat.fronts,problem,onlyPareto=T,SDR=NULL){

  if(onlyPareto){
    dat=unique(dat.fronts[dat.fronts$Pareto.front,])
  } else {
    dat=unique(dat.fronts)
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

plot.trainingDataSize <- function(problem,dim,track){
  trdat <- getTrainingDataRaw(problem,dim,track)

  stats.raw=ddply(trdat,~Problem+Step+Track,function(X) nrow(X))
  stats.raw=formatData(stats.raw)

  #p=ggplot(stats.raw, aes(x=Step,y=V1,linetype=Track))
  p=ggplot(stats.raw, aes(x=Step,y=V1,color=Track))+
    ggplotColor('Track',num = length(levels(stats.raw$Track)))

  p=p+geom_line(size=1,position=position_jitter(w=0.25, h=0))+
    facet_wrap(~Problem,ncol=4)+
    ylab(expression('Size of training set, |' * Phi * '|'))+
    axisStep(stats.raw$Step)+axisCompact

}

plot.preferenceSetSize <- function(problems,dim,track,ranks){
  stats=NULL;
  for(problem in problems){
    for(rank in ranks){
      tmp <- getTrainingDataRaw(problem,dim,track,rank,useDiff = T)
      tmp$Rank=rank
      tmp=ddply(tmp,~Problem+Step+Rank+Track,function(X) nrow(X))
      stats=rbind(stats,tmp)
    }
  }
  stats=formatData(stats)

  #stats$Rank <- factor(stats$Rank, levels=levels(stats$Rank), labels=paste0('S[',levels(stats$Rank),']'))

  p=ggplot(stats, aes(x=Step,y=V1,color=Track))+
    geom_line(size=1)+
    #facet_grid(Problem~Rank,scales='free_y',labeller = label_parsed)+
    facet_grid(.~Rank,scales='free_y',labeller = label_both)+
    ggplotColor('Track',num = length(levels(stats$Track)))+
    ylab(expression('Size of preference set, |' * S * '|'))+
    axisStep(stats$Step)+axisCompact

}
