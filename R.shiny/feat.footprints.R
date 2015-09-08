label.trdat <- function(trdat,quartiles){
  trdat.lbl=labelDifficulty(subset(trdat,Step==max(trdat$Step)-1), # might be missing last step
                            quartiles)
  trdat.lbl$FinalRho = trdat.lbl$Rho
  trdat <- merge(trdat,trdat.lbl[,c('Problem','Track','PID','FinalRho','Difficulty')],
                 by=c('Problem','Track','PID'))
  trdat <- trdat[,grep('Track|PID|Step|phi|Difficulty|Rho',colnames(trdat))]
  trdat$Rho=NULL
  return(trdat)
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
      print(nrow(ddf))
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
    if(nrow(tmp)>0){ tmp$Difficulty=diff }
    return(tmp)
  }))

  return(cor.dat)
}

plot.stepwise.test <- function(df){

  df$Feature <- factorFeature(df$Feature, simple = F)
  df$Feature <- factor(df$Feature, levels=rev(levels(df$Feature)))

  df = factorTrack(df)
  df$Difficulty=factor(df$Difficulty)

  p=ggplot(df, aes(x=Step, y=Feature)) + facet_wrap(~Track,nrow=2) +
    geom_point(data=subset(df,Significant==T), aes(Step, Feature, shape = Difficulty), color = 'black') +
    axisCompactX

  return(p)
}

plot.correlation.matrix.stepwise <- function(cor.df){
  plot.stepwise.test(cor.df) + scale_shape_manual('Significant difficulty', values = c(3, 4)) +
    ylab(expression('Correlation between' *~ phi^(k) *~ ' and ' * ~ rho))
}

plot.ks.matrix.stepwise <- function(ks.df){
  plot.stepwise.test(ks.df) + scale_shape_manual(
    expression(H[0] *~ ': Easy and Hard are drawn from the same continuous distribution'),
    values=c(8))+ylab('Kolmogorov-Smirnov Test')
}

