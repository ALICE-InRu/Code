get.quartiles <- function(dat){
  quartiles=ddply(dat,~Problem+Dimension, summarise,
                  Q1 = round(quantile(Rho,.25),digits = 2),
                  Q3 = round(quantile(Rho,.75), digits = 2))
  rownames(quartiles)=interaction(quartiles$Problem,quartiles$Dimension)
  return(quartiles)
}

checkDifficulty <- function(dat, quartiles){

  dat=merge(dat,quartiles)

  split = ddply(dat,~Problem+Dimension+SDR, summarise,
                Easy = round(mean(Rho<=Q1)*100,digits = 2),
                Hard = round(mean(Rho>Q3)*100,digits = 2))

  Easy = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho<=Q1]),N=length(PID))
  Hard = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho>=Q3]),N=length(PID))

  return(list('Quartiles'=quartiles,'Split'=split,'Easy'=Easy,'Hard'=Hard))
}


splitSDR <- function(dat,problem,dim){
  sdrs=unique(dat$SDR)
  N=length(sdrs)

  if(nrow(dat)==0){return(NULL)}
  m=matrix(nrow = N, ncol = N);
  colnames(m)=sdrs; rownames(m)=sdrs
  for(i in 1:N){
    iPID=subset(dat,SDR==sdrs[i])$PIDs[[1]]
    for(j in 1:N){
      jPID=subset(dat,SDR==sdrs[j])$PIDs[[1]]
      m[i,j]=round(length(intersect(jPID,iPID))/dat$N[i]*100,digits = 2)
    }
  }
  return(as.data.frame(m))
}

get.footprint.dat <- function(problem,dim,sameQuartiles=T,trdat=NULL){
  label <- function(trdat,quartiles){
    labelDifficulty <- function(dat,quartiles){
      dat = merge(dat,quartiles)
      dat = ddply(dat,~Problem+Dimension,mutate,
                  Difficulty=ifelse(Rho<=Q1,'Easy',ifelse(Rho>=Q3,'Hard','Medium')))
      dat$Difficulty <- factor(dat$Difficulty, levels=c('Easy','Medium','Hard'))
      dat$Q1=NULL
      dat$Q3=NULL
      return(dat)
    }
    trdat.lbl=labelDifficulty(subset(trdat,Step==max(trdat$Step)-1), # might be missing last step
                              quartiles)
    trdat.lbl$FinalRho = trdat.lbl$Rho
    trdat <- merge(trdat,trdat.lbl[,c('Problem','Track','PID','FinalRho','Difficulty')],
                   by=c('Problem','Track','PID'))
    trdat <- trdat[,grep('Track|PID|Step|phi|Difficulty|Rho',colnames(trdat))]
    trdat$Rho=NULL
    return(trdat)
  }

  if(is.null(trdat)){
    trdat <- get.files.TRDAT(problem, dim, 'ALL', useDiff = F)
  }
  trdat=subset(trdat,Followed==T)

  if(sameQuartiles){
    SDR=subset(dataset.SDR,Problem == problem & Dimension == dim & Set=='train')
    quartiles <- get.quartiles(SDR)
    trdat <- label(trdat,quartiles)
  } else {
    trdat = do.call(rbind, lapply(sdrs[1:4], function(sdr){
      SDR=subset(dataset.SDR,Problem == problem & Dimension == dim & Set=='train' & SDR==sdr)
      trdat1 <- subset(trdat, Track==sdr)
      tmp <- subset(trdat1,Step==max(Step)-1)
      tmp$Problem=problem
      tmp$Dimension=dim
      #quartiles <- get.quartiles(SDR)
      quartiles <- get.quartiles(tmp)
      trdat1 <- label(trdat1, quartiles)
      return(trdat1)
    }))
  }
  trdat <- subset(trdat,Difficulty %in% c('Easy','Hard'))
  return(trdat)
}

get.footprint.corr.rho <- function(trdat,withoutBonferroni=T,window=0){
  get.footprint.corr.rho1 <- function(bonferroniAdjust){
    do.call(rbind, lapply(sdrs[1:4], function(sdr) {
      df <- correlation.matrix.stepwise(subset(trdat,Track==sdr),'FinalRho',
                                        bonferroniAdjust = bonferroniAdjust, window = window)
      df$Track = sdr
      return(df) } ))
  }
  if(withoutBonferroni){
    corr.rho=get.footprint.corr.rho1(T)
  } else {
    B=get.footprint.corr.rho1(T)
    NB=get.footprint.corr.rho1(F)
    corr.rho=NB
    corr.rho[B$Significant,]=B[B$Significant,]
  }
  return(corr.rho)
}

get.footprint.ks <- function(trdat,withoutBonferroni=T,window=0,printTable=F){
  get.footprint.ks1 <- function(bonferroniAdjust){
    ks.rho <- do.call(rbind, lapply(sdrs[1:4], function(sdr) {
      df <- ks.matrix.stepwise(subset(trdat,Track==sdr),bonferroniAdjust,window)
      df$Track = sdr
      return(df) } ))
    ks.rho$Bonferroni=bonferroniAdjust
    return(ks.rho)
  }
  if(withoutBonferroni){
    ks=get.footprint.ks1(T)
  } else {
    B=get.footprint.ks1(T)
    NB=get.footprint.ks1(F)
    ks=NB
    ks[B$Significant,]=B[B$Significant,]
  }
  return(ks)
}

ks.matrix.stepwise <- function(df, bonferroniAdjust=T,window=0)
{

  df$Step=as.numeric(df$Step)
  TotalSteps=max(df$Step)
  values=grep('phi',colnames(df))
  values=colnames(df)[values]

  for(col in 1:length(values)){
    df[,col]=as.numeric(df[,col])
  }

  df1 <- subset(df,Difficulty=='Easy')
  df2 <- subset(df,Difficulty=='Hard')

  ## Computing the correlation matrix
  ks.matrix=matrix(nrow=length(values),ncol=TotalSteps)
  rownames(ks.matrix)=values
  colnames(ks.matrix)=1:TotalSteps

  conf.level=0.95
  alpha=1-conf.level
  if(bonferroniAdjust){
    alpha=alpha/TotalSteps
  }

  for(step in (1+window):(TotalSteps-window)){
    ddf1=subset(df1, Step<=step+window & Step>=step-window)
    ddf2=subset(df2, Step<=step+window & Step>=step-window)
    if(nrow(ddf1)>0 & nrow(ddf2)>0){
      for(col in values){
        ks.matrix[col,step] <- ks.test2(ddf1[,col],ddf2[,col],alpha)
      }
    } else { ks.matrix[col,step]=NA }
  }

  N1=nrow(subset(df1,Step==1))*(1+diff(c(-window,window)))
  N2=nrow(subset(df2,Step==1))*(1+diff(c(-window,window)))

  ks.dat <- melt(ks.matrix)
  colnames(ks.dat)=c('Feature','Step','Significant')

  if(any(is.na(ks.dat$Significant))){ ks.dat <- ks.dat[-which(is.na(ks.dat$Significant)),] }
  if(nrow(ks.dat)>0) {
    ks.dat$N.Easy = N1
    ks.dat$N.Hard = N2
    ks.dat$Track = 'ALL'
    ks.dat$Difficulty = 'Reject'
  }

  return(ks.dat)
}

correlation.matrix.stepwise <- function(f.trdat,fixedColumnName='FinalRho',bonferroniAdjust=T,window=0)
{
  correlation.matrix.stepwise1 <- function(df){

    if(nrow(df)==0){return(df)}

    df$Step=as.numeric(df$Step)
    TotalSteps=max(df$Step)
    rename=grep(fixedColumnName,colnames(df))
    colnames(df)[rename]='Fixed'

    values=grep('phi',colnames(df))
    values=colnames(df)[values]

    for(col in 1:length(values)){
      df[,col]=as.numeric(df[,col])
    }

    ## Computing the correlation matrix
    cor.matrix=matrix(nrow=length(values),ncol=TotalSteps)
    rownames(cor.matrix)=values
    colnames(cor.matrix)=1:TotalSteps

    method='pearson'
    op <- options(warn = (-1)) # suppress warnings

    for(step in (1+window):(TotalSteps-window)){
      ddf=subset(df, Step>=step-window & Step<=step+window)
      if(nrow(ddf)>0){
        for(col in values){
          cor.matrix[col,step] <- cor(ddf[,col],ddf$Fixed, use = "pairwise.complete.obs", method = method)
        }
      } else { cor.matrix[col,step]=NA }
    }

    N=nrow(subset(df,Step==1))*(1+diff(c(-window,window)))
    test.cor.matrix <- cor.matrix*sqrt(N-2)/sqrt(1-cor.matrix**2)

    conf.level=0.95
    if(bonferroniAdjust){
      alpha=1-conf.level
      conf.level = 1-alpha/TotalSteps
    }

    sign.cor = abs(test.cor.matrix) > qt(conf.level,N-2) # The Student t Distribution
    sign.cor <- melt(sign.cor)
    colnames(sign.cor)=c('Feature','Step','Significant')

    cor.matrix <- round(cor.matrix, digits = 2)
    cor.dat <- melt(cor.matrix)
    colnames(cor.dat)=c('Feature','Step',method)

    cor.dat <- merge(cor.dat, sign.cor, by=c('Feature','Step'))

    cor.dat <- cor.dat[-which(is.na(cor.dat$Significant)),]
    if(nrow(cor.dat)>0) { cor.dat$N = N }

    return(cor.dat)
  }

  cor.dat <- do.call(rbind, lapply(c('Easy','Hard'), function(diff){
    tmp <- correlation.matrix.stepwise1(subset(f.trdat,Difficulty==diff))
    if(nrow(tmp)>0){
      tmp$Difficulty=diff
      tmp$Bonferroni=bonferroniAdjust
    }
    return(tmp)
  }))

  return(cor.dat)
}

plot.stepwise.test <- function(df){

  df$Feature <- factorFeature(df$Feature, simple = F)
  df$Feature <- factor(df$Feature, levels=rev(levels(df$Feature)))

  df = factorTrack(df)
  df$Difficulty=factor(df$Difficulty)
  df$Bonferroni = factor(df$Bonferroni,levels=c(T,F))

  p=ggplot(df, aes(x=Step, y=Feature, size=Bonferroni)) + facet_wrap(~Track,nrow=2) +
    geom_point(data=subset(df,Significant==T), aes(Step, Feature, shape = Difficulty), color = 'black') +
    axisCompactX+scale_size_manual(values=c(3,1.5))

  return(p)
}

plot.correlation.matrix.stepwise <- function(cor.df){
  plot.stepwise.test(cor.df) + scale_shape_manual('Significant', values = c(3, 4)) +
    ylab(expression('Correlation between' *~ phi^(k) *~ ' and ' * ~ rho))
}

plot.ks.matrix.stepwise <- function(ks.df){
  plot.stepwise.test(ks.df) + scale_shape_manual(
    expression(H[0] *~ ': Easy and Hard are drawn from the same continuous distribution'),
    values=c(8))+ylab('Kolmogorov-Smirnov Test')
}

stat.ks.Significant <- function(ks){
  mdat=ddply(ks,~Track+N.Easy+N.Hard,summarise,Significant=sum(Significant))
  if(nrow(mdat)>1){ mdat[nrow(mdat)+1,]=c('SUM',colSums(mdat[,2:4])) }
  return(mdat)
}

stat.corr.Significant <- function(corr.rho){
  mdat=ddply(corr.rho,~Track,summarise,
             N.Easy=sum(Significant & Difficulty=='Easy'),
             N.Hard=sum(Significant & Difficulty=='Hard'))
  if(nrow(mdat)>1){ mdat[nrow(mdat)+1,]=c('SUM',colSums(mdat[,2:3])) }
  return(mdat)
}

