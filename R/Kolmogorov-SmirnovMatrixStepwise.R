ks.matrix.stepwise <- function(df,split, fixedComparison=F, alpha=0.05)
{
  splitCol = df[,grep(split,colnames(df))]
  names=unique(splitCol)
  
  if (length(names)<2 | ! ('Step' %in% colnames(df))) { return(NULL) }
    
  TotalSteps=max(df$Step)
  alphak=alpha/TotalSteps
    
  df1 <- df[df[,split]==names[1],];df1[,split]<-NULL; 
  df2 <- df[df[,split]==names[2],];df2[,split]<-NULL; 
  values=grep('Step',colnames(df1),invert=T)
  values=colnames(df1)[values]  
  
  for(col in 1:length(values)){
    df1[,col]=as.numeric(df1[,col])    
    df2[,col]=as.numeric(df2[,col])    
  }
    
  ## Computing the Kolmogorov Smirnov p-valus matrix  
  ks.matrix=matrix(nrow=length(values),ncol=TotalSteps)
  rownames(ks.matrix)=values
  colnames(ks.matrix)=1:TotalSteps
    
  for(step in 1:TotalSteps){
    ddf1=subset(df1, Step==step)
    ddf2=subset(df2, Step==step)
    if(nrow(ddf1)>0 & nrow(ddf2)>0){
      for(col in values){         
        ks.matrix[col,step]=ks.test(ddf1[,col], ddf2[,col],)$p.value      
      }      
    } else { for(col in values){ ks.matrix[col,step]=NA } }
  }

  significant <- ks.matrix>alphak  
  ks.matrix <- round(ks.matrix, digits = 2)
    
  return(list('P.values'=ks.matrix,'Significant'=significant))
}

plot.ks.matrix.stepwise <- function(ks, ylabel='')
{    
  ## Turning it all into a dataframe and removing duplicates
  library(reshape)
  
  ks.matrix=ks$Significant
  
  ks.dat <- melt(ks.matrix)
  ks.dat$rowTypes = rep(rownames(ks.matrix),ncol(ks.matrix))  
  ks.dat <- data.frame(ks.dat)
  colnames(ks.dat)[1:2]=c('Feature','Step')
  ks.dat=formatData(ks.dat)
  ks.dat$Featurelbl=factor(ks.dat$Featurelbl, levels=rev(levels(ks.dat$Featurelbl)))
  ks.dat
    
  ## Plotting
  library(ggplot2)
  library(scales)
      
  #ggplot <- function(...) ggplot2::ggplot(...) + 
  #  theme(axis.text.x = element_text(angle = 0, vjust = 1, hjust = 1), 
  #        panel.grid.major = element_blank(),
  #        panel.grid.minor = element_blank(), 
  #        panel.border = element_blank(),
  #        panel.background = element_blank(),
  #        axis.ticks = element_blank(),
  #        legend.justification = 'center',
  #        legend.position = 'top',
  #        legend.direction = "horizontal") +  
  #  scale_x_discrete(expand = c(0, 0), limits=c(min(ks.dat$X2),seq(5,max(ks.dat$X2),by=5),max(ks.dat$X2)),'step') +
  #  scale_y_discrete(expand = c(0, 0), ylabel) +
  #  scale_fill_gradient2(name=expression('Kolmogorov-Smirnov p-values'), low = 'white', high = muted("blue"), breaks=seq(0, 1, by = 0.25), limits = c(0, 1)) + 
  #  guides(fill = guide_colorbar(barwidth = 7, barheight = 1, title.position = "top", title.hjust = 0.5))  
    
  #theme_set(theme_bw())
  
  p=ggplot(ks.dat, aes(y=Featurelbl, x=Step, fill = value)) + 
    geom_tile() + 
    geom_text(data=subset(ks.dat,value==T),aes(y=Featurelbl, x=Step, label = Step), color = 'black', size = 2) + 
    facet_grid(FeatureType~.,scales='free_y',space='free_y')+
    ggplotCommon(ks.dat,ylabel=expression("Kolmogorov-Smirnov Test on easy vs. hard "*~phi))+ggplotFill(name = 'Significant p-value',2)
  
  return(p)
}