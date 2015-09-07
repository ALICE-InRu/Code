correlation.matrix.stepwise <- function(df,fixedColumnName='FinalRho',bonferroniAdjust=T)
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
    tmp <- correlation.matrix.stepwise1(subset(df,Difficulty==diff))
    if(nrow(tmp)>0){ tmp$Difficulty=diff }
    return(tmp)
  }))

  return(cor.dat)
}

plot.correlation.matrix.stepwise <- function(cor.df){

  cor.df$Feature <- factorFeature(cor.df$Feature, simple = F)
  cor.df$Feature <- factor(cor.df$Feature, levels=rev(levels(cor.df$Feature)))

  cor.df$Difficulty=factor(cor.df$Difficulty, levels=c('Easy','Medium','Hard'))
  cor.df = factorTrack(cor.df)

  p=ggplot(cor.df, aes(x=Step, y=Feature)) + facet_wrap(~Track,nrow=2)+
    geom_point(data=subset(cor.df,Significant==T), aes(Step, Feature, shape = Difficulty), color = 'black') +
    scale_shape_manual(values = c(3, 4)) + axisCompactX +
    ylab(expression('Correlation between' *~ phi^(k) *~ ' and ' * ~ rho))
  return(p)
}

