table.exhaust.paretoFront = function(paretoFront,onlyPareto=F){
  if(is.null(paretoFront)){return(NULL)}
  if(onlyPareto){paretoFront=subset(paretoFront,Pareto.front==T)}
  library('xtable')
  tmp=ddply(paretoFront,~Problem+NrFeat+Model+Bias,summarise,
            Accuracy.Optimality=round(Validation.Accuracy.Optimality,digit=2),
            Accuracy.Classification=round(Validation.Accuracy.Classification,digit=2),
            Rho=round(Validation.Rho,digit=2),
            Pareto=Pareto.front)
  #sort
  tmp=tmp[order(tmp$Problem,tmp$Rho,-tmp$Accuracy.Optimality,-tmp$Accuracy.Classification),];
  tmp$Pareto=factor(tmp$Pareto, levels=c(T,F), labels=c('$\\blacktriangle$',''))
  return(xtable(tmp))#,include.rownames=FALSE,sanitize.text.function=function(x){x})
}

plot.exhaust.paretoWeights <- function(paretoFront,timedependent=F,save=NA){
  if(is.null(paretoFront$File)){return(NULL)}

  weights=NULL
  for(file in unique(paretoFront$File)){
    tmp=get.prefWeights(file,timedependent);tmp$Type=NULL;tmp$File=file
    weights=rbind(weights,tmp)
  }
  mdat=join(weights,paretoFront,by=c('NrFeat','Model','File'))
  mdat=subset(mdat,CDR %in% paretoFront$CDR)

  colnames(mdat)[grep('Step.1',colnames(mdat))]='value'

  ## Rescale each weight to be normalised to 1
  mdat=ddply(mdat,~Problem+NrFeat+CDR,mutate,sc.value=value/sqrt(sum(value*value)))
  mdat$Feature = factorFeature(mdat$Feature, F)
  mdat$Feature = factor(mdat$Feature,levels=rev(levels(mdat$Feature)))

  p=ggplot(mdat, aes(fill=sc.value,x=CDR,y=Feature))+
    geom_tile(color='black')+
    geom_point(data=subset(mdat,Pareto.front==T),aes(label='pareto'),shape=17)+
    scale_fill_gradient2(name='Normalised\nweights', low = scales::muted("red"), mid = "white",
                         high = scales::muted("blue"), midpoint = 0, space = "rgb",
                         na.value = "grey50", guide = "colourbar")+
    facet_grid(Problem~NrFeat,scales='free_x',space='free_x',labeller = 'label_both')+
    ylab(expression('Feature'*~phi))+xlab('')+
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
          legend.position = 'right', legend.direction='vertical')

  return(p)
}

plot.exhaust.bestAcc <- function(StepwiseOptimality,bestPrefModel,save=NA){
  if(is.null(bestPrefModel)|is.null(StepwiseOptimality)) { return(NULL) }

  p0=plot.stepwiseOptimality(StepwiseOptimality,T,F)

  p=p0+facet_wrap(~Problem)+
    geom_line(data=bestPrefModel$Stepwise,aes(y=value,color=variable,size=Accuracy))+
    ggplotColor("Best",2)+scale_size_discrete(range=c(0.5,1.2))+ylab('Probability of CDR being optimal')

  if(!is.na(save)){
    dim=ifelse(length(levels(StepwiseOptimality$Stats$Dimension))>1,'ALL',StepwiseOptimality$Stats$Dimension[1])
    Bias=ifelse(levels(bestPrefModels$Bias)>1,'ALL',bestPrefModels$Bias[1])
    fname=paste(paste(subdir,'trdat',sep='/'),'prob.moveIsOptimal',dim,'OPT',Bias,'best',extension,sep='.')
    if(save=='full')
      ggsave(p,filename=fname,width=Width,height=Height.full,units=units,dpi=dpi)
    else if (save=='half')
      ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
  }
  return(p)
}

plot.exhaust.bestBoxplot <- function(bestPrefModel,SDR=NULL,save=NA){
  if(is.null(bestPrefModel)){return(NULL)}

  getBestCDR=function(bestSummary){
    CDR=NULL

    for(r in 1:nrow(bestSummary)){
      problem=bestSummary[r,'Problem']

      for(var in colnames(bestSummary)[2:ncol(bestSummary)]){
        m=regexpr('(?<File>[a-zA-Z0-9.]+.weights.[a-z]+).(?<NrFeat>[0-9]+).(?<Model>[0-9]+)',
                  bestSummary[r,var],perl=T)
        File=getAttribute(bestSummary[r,var],m,'File')
        NrFeat=getAttribute(bestSummary[r,var],m,'NrFeat',F)
        Model=getAttribute(bestSummary[r,var],m,'Model',F)
        dat=get.CDR(File,NrFeat,Model)
        if(!is.null(dat)){
          dat$Best=factor(var)
          CDR <- rbind(CDR,dat)
        }
      }
    }
    return(CDR)
  }

  CDR = getBestCDR(bestPrefModel$Summary)
  if(is.null(CDR)){return(NULL)}


  p=pref.boxplot(CDR,SDR,'Best')

  if(!is.na(save)){
    dim=ifelse(length(levels(CDR$Dimension))==1,as.character(CDR$Dimension[1]),'ALL')
    prob = ifelse(length(levels(CDR$Bias))==1,as.character(CDR$Bias[1]),'ALL')
    fname=paste(subdir,paste('boxplotRho','CDR',dim,prob,extension,sep='.'),sep='/')
    if(save=='half'){
      ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
    }
  }
  return(p)
}

plot.exhaust.acc <- function(prefSummary,save=NA){
  if(is.null(prefSummary)) return(NULL)

  p=ggplot(prefSummary,aes(y=Validation.Rho,shape=Bias))+
    facet_grid(~Problem, scales='free')+
    geom_point(aes(x=Validation.Accuracy.Classification,color='classification'))+
    geom_point(aes(x=Validation.Accuracy.Optimality,color='optimality'))+
    ggplotColor(name = "Mean stepwise", num=2)+
    ylab(expression('Expected mean for'*~rho*~'(%)'))+
    xlab('Validation accuracy (%)')

  Bias=ifelse(length(levels(prefSummary$Bias))>1,'ALL',prefSummary$Bias[1])
  if(Bias!='ALL'){p=p+scale_shape_discrete(guide = F)}

  if(!is.na(save)){
    Problem=ifelse(length(levels(prefSummary$Problem))>1,'ALL',prefSummary$Problem[1])
    fname=paste(subdir,paste('training','accuracy',Bias,Problem,extension,sep='.'),sep='/')
    if(save=='half'){
      ggsave(fname,p,units=units,width=Width,height=Height.half)
    }
  }
  return(p)
}

plot.exhaust.paretoFront <- function(prefSummary,paretoFront,plotAllSolutions=T,save=NA){
  if(is.null(prefSummary)|is.null(paretoFront)) return(NULL)
  p=ggplot(prefSummary,aes(x=Validation.Accuracy.Optimality,
                           y=Validation.Rho,
                           color=as.factor(NrFeat)))+
    facet_grid(~Problem,scales='free_y')

  if(length(unique(paretoFront$Bias))>1){
    if(plotAllSolutions){p=p+geom_point(aes(shape=Bias))}
    p=p+geom_point(data=paretoFront,aes(shape=Bias,size=Pareto.front))
  } else {
    if(plotAllSolutions){p=p+geom_point()}
    p=p+geom_point(data=paretoFront,aes(shape=Pareto.front),size=5)
  }

  p=p+geom_line(data=paretoFront,size=1)+
    guides(size=FALSE)+ggplotColor('Feature count',4)+
    geom_text(data=paretoFront,aes(label=Model),color='black',size=3)+
    xlab('Mean stepwise optimality accuracy (%)')+
    ylab(expression('Expected mean for'*~rho*~'(%)'))+
    guides(
      colour = guide_legend(ncol = 2, byrow = T),
      shape = guide_legend(ncol = 1, byrow = T)
    ) + themeVerticalLegend

  if(!is.na(save)){
    Bias=ifelse(levels(prefSummary$Bias)>1,'ALL',prefSummary$Bias[1])
    Problem=ifelse(levels(prefSummary$Problem)>1,'ALL',prefSummary$Problem[1])
    fname=paste(subdir,paste('pareto',Bias,Problem,extension,sep='.'),sep='/')
    if(save=='full')
      ggsave(fname,p,units=units,width=Width,height=Height.full)
    else if (save=='half')
      ggsave(fname,p,units=units,width=Width,height=Height.half)
  }


  return(p)
}

rankPareto <- function(x,byVar){

  x=plyr::arrange(x, desc(x[,byVar]), x$Validation.Rho)
  x$Pareto.front=F
  x[which(!duplicated(cummin(x$Validation.Rho))),'Pareto.front']=T

  front=subset(x,Pareto.front==T)
  front=front[order(front$Validation.Rho),]

  return(list(Front=front,Ranked=x))
}

get.prefAccuracy <- function(model,type=NULL,onlyMean=F){
  m=regexpr(".(?<Dimension>[0-9]+x[0-9]+).",model,perl=T)
  dim=getAttribute(model,m,'Dimension')
  acc=read_csv(paste0(DataDir,'PREF/weights/',model,'.csv'))
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

get.optAccuracy <- function(model,reportMean=T){
  m=regexpr(".(?<Dimension>[0-9]+x[0-9]+).",model,perl=T)
  dim=getAttribute(model,m,'Dimension')
  fname=paste0(DataDir,'Stepwise/accuracy/',paste0(model,'.csv'))
  if(!file.exists(fname)){ return(NULL)}
  acc = read_csv(fname)

  m=regexpr("F(?<NrFeat>[0-9]+).M(?<Model>[0-9]+)", acc$CDR, perl=T)
  acc$NrFeat=getAttribute(acc$CDR,m,'NrFeat',F)
  acc$Model=getAttribute(acc$CDR,m,'Model',F)
  acc$variable=NULL
  acc=melt(acc,id.vars = c('NrFeat','Model'), variable.name = 'Step', value.name = 'validation.isOptimal')
  acc$Step=as.numeric(substr(acc$Step,6,100))
  acc$test.isOptimal=NA
  acc$train.isOptimal=NA

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

get.prefSummary <- function(problems,dim,track,rank,timedependent,bias){

  get.CDR.Exhaust  <- function(model){
    CDR <- get.CDR(model,'train')
    minNum=choose(16,1)+choose(16,2)+choose(16,3)+choose(16,16)
    num=length(unique(CDR$CDR))
    if(num<minNum) {
      return(NULL)
    }
    return(CDR)
  }

  get.prefSummary1 <- function(model,Set='Validation'){
    CDR <- get.CDR.Exhaust(model)
    vars = c('Bias','CDR','NrFeat','Model')
    rho.stats = rho.statistic(CDR,vars,T)
    if(is.null(rho.stats)){return(NULL)}
    rho.stats = rho.stats[,c(vars,paste(Set,'Rho',sep='.'),paste0('N',Set))]

    acc.pref = get.prefAccuracy(model,paste(Set,'Accuracy',sep='.'),onlyMean = T)
    if(is.null(acc.pref)){return(NULL)}

    pref=join(rho.stats, acc.pref, by = c('NrFeat','Model'))

    # Make a distinction between mean cross-validation accuracy and stepwise training accuracy
    acc.opt = get.optAccuracy(model,T)
    if(is.null(acc.opt)){return(NULL)}
    acc.opt=acc.opt[,c('NrFeat','Model',paste(Set,'Accuracy',sep='.'))]
    pref=merge(pref, acc.opt, by = c('NrFeat','Model'),suffixes = c('.Classification','.Optimality'))

    pref=rankPareto(pref,paste(Set,'Accuracy.Optimality',sep='.'))$Ranked
    pref$File=model
    return(pref)
  }

  file_list <- get.CDR.file_list(problems, dim, track, rank, timedependent, bias)
  file_list = file_list[grep('exhaust',file_list)]

  prefSummary <- ldply(file_list, get.prefSummary1)

  if(nrow(prefSummary)==0){return(NULL)}

  m=regexpr('exhaust.(?<Problem>[j|f].[a-z_1]+).(?<Dimension>[0-9]+x[0-9]+)',prefSummary$File,perl=T)
  prefSummary$Problem <- getAttribute(prefSummary$File, m, 'Problem')
  prefSummary$Problem <- factorProblem(prefSummary)
  prefSummary$Dimension <- dim
  prefSummary$Dimension <- factorDimension(prefSummary)

  return(prefSummary)
}

get.bestPrefModel <- function(paretoFront){
  if(is.null(paretoFront)) return(NULL)

  paretoFront$BestInfo=interaction(paretoFront$File,paretoFront$NrFeat,paretoFront$Model)

  #best <- list(
  #  'Max.Accuracy.Optimality'=merge(
  #    aggregate(Validation.Accuracy.Optimality ~ Problem, paretoFront, max), paretoFront),
  #  'Min.Rho'=merge(
  #    aggregate(Validation.Rho ~ Problem, paretoFront, min), paretoFront))

  Summary = ddply(paretoFront,~Problem,summarise,
                  Max.Accuracy.Optimality=BestInfo[
                    Validation.Accuracy.Optimality==max(Validation.Accuracy.Optimality)],
                  Min.Rho=BestInfo[Validation.Rho==min(Validation.Rho)])

  Stepwise=NULL
  for(i in 1:nrow(Summary))
  {
    tmp=subset(paretoFront, Problem==Summary$Problem[i] & BestInfo==Summary$Max.Accuracy.Optimality[i])
    acc=subset(get.optAccuracy(tmp$File,F),NrFeat==tmp$NrFeat & Model==tmp$Model)
    acc=acc[,c('Step','validation.isOptimal')];colnames(acc)[2]='value'
    acc$Problem=tmp$Problem;
    acc$CDR=tmp$CDR
    acc$variable='Max.Accuracy.Optimality'
    acc$Accuracy='Optimality'
    Stepwise=rbind(Stepwise,acc)
    acc=subset(get.prefAccuracy(tmp$File,'Validation.Accuracy'),NrFeat==tmp$NrFeat & Model==tmp$Model)
    acc=acc[,c('Step','value')]
    acc$Problem=tmp$Problem;
    acc$CDR=tmp$CDR
    acc$variable='Max.Accuracy.Optimality'
    acc$Accuracy='Classification'
    Stepwise=rbind(Stepwise,acc)

    tmp=subset(paretoFront, Problem==Summary$Problem[i] & BestInfo==Summary$Min.Rho[i])
    rho=subset(get.optAccuracy(tmp$File,F),NrFeat==tmp$NrFeat & Model==tmp$Model)
    rho=rho[,c('Step','validation.isOptimal')];colnames(rho)[2]='value'
    rho$Problem=tmp$Problem
    rho$CDR=tmp$CDR
    rho$variable='Min.Rho'
    rho$Accuracy='Optimality'
    Stepwise=rbind(Stepwise,rho)
    rho=subset(get.prefAccuracy(tmp$File,'Validation.Accuracy'),NrFeat==tmp$NrFeat & Model==tmp$Model)
    rho=rho[,c('Step','value')]
    rho$Problem=tmp$Problem
    rho$CDR=tmp$CDR
    rho$variable='Min.Rho'
    rho$Accuracy='Classification'
    Stepwise=rbind(Stepwise,rho)
  }

  return(list('Summary'=Summary,'Stepwise'=Stepwise))
}

get.pareto.ks <- function(paretoFront,problem,onlyPareto=T,SDR=NULL){
  if(is.null(paretoFront)){return(NULL)}

  ks.matrix <- function(dat,var,label){
    if(nrow(dat)==0) return(NULL)
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

  if(onlyPareto){
    dat=unique(paretoFront[paretoFront$Pareto.front,])
  } else {
    dat=unique(paretoFront)
  }
  dat=subset(dat,Problem==problem)
  if(nrow(dat)==0){return(NULL)}

  dat$CDR=factorCDR(dat)
  dat.Acc=NULL
  dat.Rho=NULL
  for(use in 1:nrow(dat)){
    tmp=subset(get.optAccuracy(dat[use,'File'],F),NrFeat==dat[use,'NrFeat'] & Model==dat[use,'Model'])
    tmp$Problem=dat[use,'Problem']
    tmp$CDR=dat[use,'CDR']
    dat.Acc=rbind(dat.Acc,tmp)

    tmp=get.CDR(dat[use,'File'],dat[use,'NrFeat'],dat[use,'Model'])
    tmp$CDR=dat[use,'CDR']
    dat.Rho=rbind(dat.Rho,tmp)
  }

  if(!is.null(SDR)){
    SDR <- subset(SDR, Name %in% dat.Rho$Name)
    SDR$CDR=SDR$SDR
    dat.Rho=rbind(dat.Rho[,c('Problem','CDR','Rho','Set','Name')],SDR[,c('Problem','CDR','Rho','Set','Name')])
  } else { dat.Rho=dat.Rho[,c('Problem','CDR','Rho','Set','Name')] }

  stat.Rho=ddply(dat.Rho,~Problem+CDR+Set, function(X) data.frame(Rho=I(list(unlist(X$Rho)))))
  stat.Acc=ddply(dat.Acc,~Problem+CDR, function(X) data.frame(isOptimal=I(list(unlist(X$validation.isOptimal)))))

  ks.Acc = ks.matrix(stat.Acc,'isOptimal','CDR')
  ks.Rho.train=ks.matrix(subset(stat.Rho, Set=='train'),'Rho','CDR')
  ks.Rho.test=ks.matrix(subset(stat.Rho, Set=='test'),'Rho','CDR')
  return(list('Acc'=ks.Acc,'Rho.test'=ks.Rho.test,'Rho.train'=ks.Rho.train))
}

get.paretoFront <- function(prefSummary){
  if(is.null(prefSummary)) return(NULL)

  pareto.ranking.wrtNrFeat <- function(pref){
    front=NULL
    for(nrFeat in unique(pref$NrFeat)){
      pdat=subset(pref,NrFeat==nrFeat)
      front=rbind(front,rankPareto(pdat,'Validation.Accuracy.Optimality')$Front)
    }
    front=rankPareto(front,'Validation.Accuracy.Optimality')$Ranked
    return(front)
  }

  fronts=NULL
  for(problem in levels(prefSummary$Problem)){
    front=pareto.ranking.wrtNrFeat(subset(prefSummary,Problem==problem))
    fronts=rbind(fronts,front)
  }
  fronts$Problem=factorProblem(fronts)
  fronts$CDR=factorCDR(fronts)
  return(fronts)
}

