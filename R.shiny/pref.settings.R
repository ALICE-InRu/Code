get.stepwiseBias <- function(steps,problem,dim,bias){
  nDim=numericDimension(dim)
  half=round(nDim/2,digit=0)
  last=nDim-half
  w=switch(bias,
           'linear'=1:max(steps),
           'opt'=1-get.StepwiseOptimality(problem,dim,'OPT')$Stats$rnd.mu,
           'bcs'=subset(get.BestWorst(problem,dim),Track=='OPT' & Followed==F)$best.mu,
           'wcs'=subset(get.BestWorst(problem,dim),Track=='OPT' & Followed==F)$worst.mu,
           'dbl1st'=c(rep(2,half),rep(1,last)),
           'dbl2nd'=c(rep(1,half),rep(2,last)),
           rep(1,nDim))
  w=w/sum(w); # normalize
  return(w[steps])
}

rho.statistic <- function(dat,variables,useValidationSet=F){
  if(useValidationSet){
    dat$Set <- factorSet(dat$Set)
    pids <- unique(dat$PID[which(dat$Set=='train')])
    NTrain <- quantile(pids,0.8)
    #validation=sample(pids, length(pids)*0.2, replace = F) # 20% of training saved for validation
    dat$Set[dat$Set=='train' & dat$PID > NTrain]='validation' # 20% of training data saved for validation
  }
  rho.stats = ddply(dat,c('Problem','Dimension',variables), summarise,
                    Training.Rho = round(mean(Rho[Set=='train']), digits = 5),
                    NTrain = sum(Set=='train'),
                    Validation.Rho = round(mean(Rho[Set=='validation']), digits = 5),
                    NValidation = sum(Set=='validation'),
                    Test.Rho = round(mean(Rho[Set=='test']), digits = 5),
                    NTest = sum(Set=='test'))

  if(!useValidationSet){
    rho.stats$Validation.Rho=NULL
    rho.stats$NValidation=NULL
  }

  return(rho.stats)
}

create.prefModel <- function(problem,dim,track,rank,bias,timedependent,exhaustive,lmax,scale=F){
  library('LiblineaR')

  if(substr(track,1,2)=='IL')
  {
    supstr=substr(track,3,100)
    track=paste0('IL',length(list.files(path = paste0(DataDir,'Training'),paste('trdat',problem,dim,paste0('IL[0-9]+',supstr),'Local','diff',rank,'csv',sep='.'))),supstr)
  }

  logFile <- function(exhaustive){
    file = paste(problem,dim,rank,track,bias,'weights',
                 ifelse(timedependent,'timedependent','timeindependent'),'csv',sep='.')
    if(scale){file=paste('sc',file,sep='.')}
    file = paste0(DataDir,'PREF/weights/',ifelse(exhaustive,'exhaust.','full.'),file)
    return(file)
  }

  fileName <- logFile(exhaustive)
  if(file.exists(fileName)|(!exhaustive & file.exists(logFile(T)))){
    return(paste('Logfile',fileName,'already exists.'))
  }
  print(fileName)

  getTrainingData <- function(){

    useDiff=T
    dat <- get.files.TRDAT(problem,dim,track,rank,useDiff)
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
    info=paste(info, paste(format(stringr::str_split_fixed(colnames(features),'phi.',2)[,2], justfy=F),' ',collapse=''), sep='\n')
    print(cat(info))

    return(list(Y=label,X=features,PID=dat$PID,STEP=dat$Step, Dimension=dim,Problem=problem,Info=info))
  }

  dat = getTrainingData()
  if(is.null(dat)){return('Data is null! Check if trainingdata exists for chosen trajectory.')}

  linearWeights <- function(dat){

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
        model=stepwiseLiblinearModel(dat$X[train,phiCol], dat$Y[train], dat$Bias[train], dat$STEP[train])
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
        model = liblinearModel(dat$X[train,phiCol], dat$Y[train], dat$Bias[train],lmax)
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

      if(!file.exists(fileName)){ # create header
        cat('Type','NrFeat','Model','Feature','mean',paste('Step',1:nrSteps,sep='.'),sep=',', file = fileName, append = F)
      }

      for(N in 1:nrow(Info)){
        for(col in 1:nrFeat){
          W=Model[N][[1]][,col];
          cat('\nWeight',nrFeat,N,colnames(Model[N][[1]])[col],NA,W,sep=',', file = fileName, append = T)
        }
        cat('\nTraining.Accuracy',nrFeat,N,NA,
            round(mean(stepwise.training.acc[N][[1]]),digits = 2),
            round(stepwise.training.acc[N][[1]],digits = 2),
            sep=',', file = fileName, append = T)
        cat('\nValidation.Accuracy',nrFeat,N,NA,
            round(mean(stepwise.validation.acc[N][[1]],digits = 2)),
            round(stepwise.validation.acc[N][[1]],digits = 2),sep=',', file = fileName, append = T)
      }
    }

    dat$Bias = get.stepwiseBias(dat$STEP, problem, dim, bias)
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

  allResults=linearWeights(dat)
  return(paste('Trained on',round(100*lmax/nrow(dat$X)),'% of the total preference set'))
}

