table.exhaust.paretoFront = function(paretoFront,onlyPareto=F){
  if(is.null(paretoFront)){return(NULL)}
  if(onlyPareto){paretoFront=subset(paretoFront,Pareto.front==T)}
  library('xtable')
  tmp=ddply(paretoFront,~Problem+NrFeat+Model,summarise,
            Accuracy.Optimality=round(Validation.Accuracy.Optimality,digit=2),
            Accuracy.Classification=round(Validation.Accuracy.Classification,digit=2),
            Rho=round(Validation.Rho,digit=2),
            Pareto=Pareto.front)
  #sort
  tmp=tmp[order(tmp$Problem,tmp$Rho,-tmp$Accuracy.Optimality,-tmp$Accuracy.Classification),];
  tmp$Pareto=factor(tmp$Pareto, levels=c(T,F), labels=c('$\\blacktriangle$',''))
  return(xtable(tmp))#,include.rownames=FALSE,sanitize.text.function=function(x){x})
}

plot.exhaust.paretoWeights <- function(paretoFront,save=NA,tiltText=T,rhoTxt=T){
  if(is.null(paretoFront$File)){return(NULL)}

  weights=NULL
  for(file in unique(paretoFront$File)){
    tmp=get.prefWeights(file);tmp$Type=NULL;tmp$File=file
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
    scale_fill_gradient2(name='Scaled\nweights', low = scales::muted("red"), mid = "white",
                         high = scales::muted("blue"), midpoint = 0, space = "rgb",
                         na.value = "grey50", guide = "colourbar")+
    facet_grid(Problem~NrFeat,scales='free_x',space='free_x',
               labeller = ifelse(is.na(save),'label_both','label_value'))+
    ylab(expression('Feature'*~phi))+scale_y_discrete(expand = c(0,0))+
    xlab(NULL)+scale_x_discrete(expand = c(0,0))+themeVerticalLegend

  if(any(mdat$Pareto.front)){
    p=p+geom_point(data=subset(mdat,Pareto.front==T),aes(label='pareto'),shape=17)
  }
  if(rhoTxt){
    txtDat <- ddply(mdat,~Problem+Dimension+NrFeat+Model+CDR,function(x) c(
      sc.value=0,
      Rho=round(unique(x$Validation.Rho),0),
      AccOpt=round(unique(x$Validation.Accuracy.Optimality),0),
      AccClass=round(unique(x$Validation.Accuracy.Classification),0)))
    p <- p+geom_text(data=txtDat,y=-.1,size=3,aes(label=paste0('  ',Rho,'\n',AccOpt,'/',AccClass)),
                     hjust=0) + expand_limits(y=-1)
    p <- p + annotate("text", label = paste0('Rho:\nAcc:'), x = 1, y = -0.1, size = 3, hjust=1)
  }

  if(tiltText)
    p <- p+theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
               legend.position = 'right', legend.direction='vertical')

  if(!is.na(save)){
    p <- p + ylab(NULL)
    problem = ifelse(length(levels(mdat$Problem))>1,'ALL',mdat$Problem[1])
    dim=ifelse(length(levels(mdat$Dimension))>1,'ALL',as.character(mdat$Dimension[1]))
    fname=paste(paste(subdir,problem,'pareto',sep='/'),dim,'phi',extension,sep='.')
    if (save=='half')
      ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
  }
  return(p)
}

plot.exhaust.bestAcc <- function(StepwiseOptimality,bestPrefModel,save=NA){
  if(is.null(bestPrefModel)|is.null(StepwiseOptimality)) { return(NULL) }

  StepwiseOptimality$Stats = subset(StepwiseOptimality$Stats,Problem %in% bestPrefModel$Summary$Problem)
  StepwiseOptimality$Raw = subset(StepwiseOptimality$Raw,Problem %in% bestPrefModel$Summary$Problem)

  dim=ifelse(length(levels(bestPrefModel$Summary$Dimension))>1,'ALL',as.character(bestPrefModel$Summary$Dimension[1]))
  StepwiseOptimality$Stats$Dimension=dim
  bestPrefModel$Stepwise$Dimension=dim

  p0=plot.stepwiseOptimality(StepwiseOptimality,dim,T,F)

  p=p0+facet_wrap(~Problem+Dimension)+
    geom_line(data=bestPrefModel$Stepwise,aes(y=value,color=variable,size=Accuracy))+
    ggplotColor("Best",2)+scale_size_discrete(range=c(0.5,1.2))+ylab('CDR validation accuracy (%)')

  if(!is.na(save)){
    fname=paste(paste(subdir,'trdat',sep='/'),'prob.moveIsOptimal',dim,'OPT','best',extension,sep='.')
    if(save=='full')
      ggsave(p,filename=fname,width=Width,height=Height.full,units=units,dpi=dpi)
    else if (save=='half')
      ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
  }
  return(p)
}

get.bestExhaustCDR <- function(bestSummary){
  CDR=NULL
  for(r in 1:nrow(bestSummary)){
    problem=bestSummary[r,'Problem']
    dat=get.CDR(bestSummary[r,'File'],bestSummary[r,'NrFeat'],bestSummary[r,'Model'])
    if(!is.null(dat)){
      dat$Best=factor(bestSummary[r,'variable'])
      CDR <- rbind(CDR,dat)
    }
  }
  return(CDR)
}

stat.exhaust.bestCDR <- function(CDR){
  dat=ddply(CDR,~Problem+Dimension+NrFeat+Model+Best+Set,function(x) c(summary(x$Rho),N=nrow(x)))
  dat$Problem <- factorProblem(dat,F)
  arrange(dat,Problem)
}

plot.exhaust.bestBoxplot <- function(bestPrefModel,SDR=NULL,save=NA,tiltText=T){
  if(is.null(bestPrefModel)){return(NULL)}

  CDR = get.bestExhaustCDR(bestPrefModel$Summary)
  if(is.null(CDR)){return(NULL)}

  if(!is.null(SDR)){   SDR <- subset(SDR, Set %in% CDR$Set) }
  p=pref.boxplot(CDR,SDR,'Best',tiltText = tiltText)

  if(!is.na(save)){
    dim=ifelse(length(levels(CDR$Dimension))==1,as.character(CDR$Dimension[1]),'ALL')
    fname=paste(subdir,paste('boxplotRho','CDR',dim,extension,sep='.'),sep='/')
    if(save=='half'){
      ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
    }
  }
  return(p)
}

plot.exhaust.acc <- function(prefSummary,save=NA,best=NULL){
  if(is.null(prefSummary)) return(NULL)

  p=ggplot(prefSummary,aes(y=Validation.Rho))+
    facet_wrap(~Problem+Dimension, scales='free',nrow=1)+
    geom_point(aes(x=Validation.Accuracy.Classification,color='classification'))+
    geom_point(aes(x=Validation.Accuracy.Optimality,color='optimality'))+
    ggplotColor(name = "Mean stepwise", num=2)+
    ylab(expression('Expected mean for,'*~rho*~'(%)'))+
    xlab('Validation accuracy (%)')

  if(!is.null(best)){
    p <- p+geom_segment(data=best,
                        arrow = arrow(length = unit(6, "points"),type='closed',ends='both'),
                        aes(x=Validation.Accuracy.Classification,
                            xend=Validation.Accuracy.Optimality,
                            yend=Validation.Rho,linetype=variable),color='red')+
      scale_linetype_discrete('Best')
  }

  if(!is.na(save)){
    Problem=ifelse(length(levels(prefSummary$Problem))>1,'ALL',prefSummary$Problem[1])
    fname=paste(subdir,paste('training','accuracy',Problem,extension,sep='.'),sep='/')
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
    facet_wrap(~Problem+Dimension,scales='free',nrow=1)

  if(plotAllSolutions){p=p+geom_point()}
  p=p+geom_point(data=paretoFront,aes(shape=Pareto.front),size=5)

  p=p+geom_line(data=paretoFront,size=1)+
    guides(size=FALSE)+ggplotColor('Feature count',4)+
    geom_text(data=paretoFront,aes(label=Model),color='black',size=3)+
    xlab(expression('Mean stepwise optimality accuracy,'*~ bar(xi[pi]^'*') *~'(%)'))+
    ylab(expression('Expected mean for,'*~rho*~'(%)'))

  if(!is.na(save)){
    Problem=ifelse(length(levels(prefSummary$Problem))>1,'ALL',prefSummary$Problem[1])
    fname=paste(subdir,paste('pareto',Problem,'png',sep='.'),sep='/')
    if(save=='full')
      ggsave(fname,p,units=units,width=Width,height=Height.full)
    else if (save=='half')
      ggsave(fname,p,units=units,width=Width,height=Height.half)
  } else {
    p <- p + guides(colour = guide_legend(ncol = 2, byrow = T),
                    shape = guide_legend(ncol = 1, byrow = T)
                    ) + themeVerticalLegend

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
  if(!file.exists(fname)){ set.optAccuracy(model) }
  acc = read_csv(fname)
  colnames(acc)[1]='CDR'

  m=regexpr("F(?<NrFeat>[0-9]+).M(?<Model>[0-9]+)", acc$CDR, perl=T)
  acc$NrFeat=getAttribute(acc$CDR,m,'NrFeat',F)
  acc$Model=getAttribute(acc$CDR,m,'Model',F)
  acc$CDR=NULL
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

set.optAccuracy <- function(model){

  fname=paste0(DataDir,'Stepwise/accuracy/',paste0(model,'.csv'))

  m=regexpr('exhaust.(?<Problem>[a-z].[a-z]+).(?<Dimension>[0-9]+x[0-9]+).(?<Rank>[a-z]).(?<Track>[A-Z]+)',model,perl=T)
  dim=getAttribute(model,m,'Dimension')
  problem=getAttribute(model,m,'Problem')
  rank=getAttribute(model,m,'Rank')
  track=getAttribute(model,m,'Track')

  if(file.exists(fname)){ opt.acc=read.csv(fname)}else{
    print(fname)
    weights = get.prefWeights(model,T)
    trdat = get.files.TRDAT(problem,dim,track,rank)
    trdat$isOPT=trdat$Rho==0
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
    vars = c('CDR','NrFeat','Model')
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

  file_list <- get.CDR.file_list(problems, dim, track, rank, timedependent,bias = bias)
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
  paretoFront = subset(paretoFront, Pareto.front==T)

  best <- list(
    'Max.Acc.Opt'=merge(
      aggregate(Validation.Accuracy.Optimality ~ Problem, paretoFront, max), paretoFront),
    'Min.Rho'=merge(
      aggregate(Validation.Rho ~ Problem, paretoFront, min), paretoFront))

  Stepwise=NULL
  for(var in names(best)){
    for(r in 1:nrow(best[var][[1]])){
      tmp=best[var][[1]][r,]
      acc=subset(get.optAccuracy(tmp$File,F),NrFeat==tmp$NrFeat & Model==tmp$Model)
      acc=acc[,c('Step','validation.isOptimal')];colnames(acc)[2]='value'
      acc$Problem=tmp$Problem;
      acc$CDR=tmp$CDR
      acc$variable=var
      acc$Accuracy='Optimality'
      Stepwise=rbind(Stepwise,acc)

      acc=subset(get.prefAccuracy(tmp$File,'Validation.Accuracy'),NrFeat==tmp$NrFeat & Model==tmp$Model)
      acc=acc[,c('Step','value')]
      acc$Problem=tmp$Problem;
      acc$CDR=tmp$CDR
      acc$variable=var
      acc$Accuracy='Classification'
      Stepwise=rbind(Stepwise,acc)

    }
    best[var][[1]] = subset(best[var][[1]],Problem %in% Stepwise$Problem & CDR %in% Stepwise$CDR)
  }

  Summary <- rbind(data.frame(best$Min.Rho,'variable'='Min.Rho'),
                   data.frame(best$Max.Acc.Opt,'variable'='Max.Acc.Opt'))

  return(list('Summary'=Summary,'Stepwise'=Stepwise))
}

get.pareto.ks <- function(paretoFront,problem,onlyPareto=T,SDR=NULL){
  if(is.null(paretoFront)){return(NULL)}

  ks.matrix <- function(dat,var,label){
    if(nrow(dat)==0) return(NULL)
    ks.mat=matrix(NA,nrow=length(dat[,label]),ncol=length(dat[,label]))
    rownames(ks.mat)=dat[,label]
    colnames(ks.mat)=dat[,label]

    for(c1 in 1:ncol(ks.mat)){
      for(c2 in c1:ncol(ks.mat)){
        #ks.mat[c1,c2]=ks.test2(dat[c1,var][[1]], dat[c2,var][[1]])
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

