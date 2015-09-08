ks.matrix.stepwise <- function(df, bonferroniAdjust=T)
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

  op <- options(warn = (-1)) # suppress warnings

  for(step in 1:TotalSteps){
    ddf1=subset(df1, Step==step)
    ddf2=subset(df2, Step==step)
    if(nrow(ddf1)>0 & nrow(ddf2)>0){
      for(col in values){
        ks.matrix[col,step] <- ks.test(ddf1[,col],ddf2[,col])$p
      }
    } else { ks.matrix[col,step]=NA }
  }

  N1=nrow(subset(df1,Step==1))
  N2=nrow(subset(df2,Step==1))

  conf.level=0.95
  if(bonferroniAdjust){
    alpha=1-conf.level
    conf.level = 1-alpha/TotalSteps
  }

  sign.ks = abs(ks.matrix) > conf.level # Kolmogorov-Smirnov test: a two-sample test of the null
  #hypothesis that 'Easy' and 'Hard' were drawn from the same continuous distribution is performed.
  sign.ks <- melt(sign.ks)
  colnames(sign.ks)=c('Feature','Step','Significant')

  ks.matrix <- round(ks.matrix, digits = 2)
  ks.dat <- melt(ks.matrix)
  colnames(ks.dat)=c('Feature','Step','Kolmogorov-Smirnov')

  ks.dat <- merge(ks.dat, sign.ks, by=c('Feature','Step'))

  if(any(is.na(ks.dat$Significant))){ ks.dat <- ks.dat[-which(is.na(ks.dat$Significant)),] }
  if(nrow(ks.dat)>0) {
    ks.dat$N.Easy = N1
    ks.dat$N.Hard = N2
    ks.dat$Track = 'ALL'
    ks.dat$Difficulty = 'Easy vs. Hard'
  }

  return(ks.dat)
}

correlation.matrix.stepwise <- function(f.trdat,fixedColumnName='FinalRho',bonferroniAdjust=T)
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

    for(step in 1:TotalSteps){
      ddf=subset(df, Step==step)
      if(nrow(ddf)>0){
        for(col in values){
          cor.matrix[col,step] <- cor(ddf[,col],ddf$Fixed, use = "pairwise.complete.obs", method = method)
        }
      } else { cor.matrix[col,step]=NA }
    }

    N=nrow(subset(df,Step==1))
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
  df$Difficulty=factor(df$Difficulty, levels=c('Easy','Easy vs. Hard','Hard'))

  p=ggplot(df, aes(x=Step, y=Feature)) + facet_wrap(~Track,nrow=2) +
    geom_point(data=subset(df,Significant==T), aes(Step, Feature, shape = Difficulty), color = 'black') +
    axisCompactX

  return(p)
}

plot.correlation.matrix.stepwise <- function(cor.df){
  plot.stepwise.test(cor.df) + scale_shape_manual(values = c(3, 4)) +
    ylab(expression('Correlation between' *~ phi^(k) *~ ' and ' * ~ rho))
}

plot.ks.matrix.stepwise <- function(ks.df){
  plot.stepwise.test(ks.df) + scale_shape_manual(values=c(8))+ylab('Kolmogorov-Smirnov Test')
}

