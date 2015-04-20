correlation.matrix.stepwise <- function(df, fixedColumnName)
{ 
  method = 'spearman'
  
  df$Step=as.numeric(df$Step)
  TotalSteps=max(df$Step)  
  rename=grep(fixedColumnName,colnames(df))  
  colnames(df)[rename]='Fixed'
  
  values=grep('Step|Fixed',colnames(df),invert=T)
  values=colnames(df)[values]
  
  for(col in 1:length(values)){
    df[,col]=as.numeric(df[,col])        
  }  
  
  ## Computing the correlation matrix  
  cor.matrix=matrix(nrow=length(values),ncol=TotalSteps)
  rownames(cor.matrix)=values
  colnames(cor.matrix)=1:TotalSteps
  
  #conf.level=0.95
  #alpha=1-conf.level;
  #stepwise.conf.level=1-alpha/TotalSteps;
  
  for(step in 1:TotalSteps){
    ddf=subset(df, Step==step)
    if(nrow(ddf)>0){
      for(col in values){         
        cor.matrix[col,step]=cor(ddf[,col],ddf$Fixed, use = "pairwise.complete.obs", method = method)      
      }      
    } else { cor.matrix[col,step]=NA }
  }
  
  cor.matrix <- round(cor.matrix, digits = 2)
  cor.matrix    
  
  return(cor.matrix)
}

plot.correlation.matrix.stepwise <- function(cor.matrix, txtsize=2.5){

  #cor.matrix <- abs(cor.matrix)
  cor.matrix
    
  ## Turning it all into a dataframe and removing duplicates
  if(!is.data.frame(cor.matrix))
  {
    library(reshape)    
    cor.dat=melt(cor.mat); colnames(cor.dat)[1:2]=c('Feature','Step'); cor.dat=formatData(cor.dat)
    cor.dat <- data.frame(cor.dat)
    cor.dat$Featurelbl=factor(cor.dat$Featurelbl, levels=rev(levels(cor.dat$Featurelbl)))
    cor.dat <- cor.dat[-which(is.na(cor.dat[, 3])),]    
    cor.dat
  } else { cor.dat = cor.matrix }
    
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
  #  scale_x_discrete(expand = c(0, 0), limits=c(min(cor.dat$Step),seq(5,max(cor.dat$Step),by=5),max(cor.dat$Step)),'step') +
  #  scale_y_discrete(expand = c(0, 0), '') +
  #  scale_fill_gradient2(name=expression("Spearman" * ~ rho), low = muted("red"), high = muted("blue"), midpoint=0, breaks=seq(-1, 1, by = 0.5), limits = c(-1, 1)) +
  #  guides(fill = guide_colorbar(barwidth = 7, barheight = 1, title.position = "top", title.hjust = 0.5))  
    
  
  p=ggplot(cor.dat, aes(x=Step, y=Featurelbl, fill = value)) + 
    geom_tile() + 
    geom_text(aes(Step, Featurelbl, label = value), color = 'black', size = txtsize) +  
    facet_grid(FeatureType~.,scales='free_y',space='free_y')+
    ggplotCommon(cor.dat,ylabel=expression('Correlation between' *~ phi[k] *~ ' and ' * ~ rho^opt))+scale_fill_gradient2(name=expression("Spearman" * ~ rho * ~ ' '), low = muted("red"), high = muted("blue"), midpoint=0, breaks=c(-1,-0.3,0.3,1), limits = c(-1, 1))
  
  return(p)
}

plot.correlation.matrices.stepwise <- function(cor.mat1, first, cor.mat2, second)
{ 
  
  ## Turning it all into a dataframe and removing duplicates
  library(reshape)
  
  cor.dat1=melt(cor.mat1); cor.dat1$Type=first;colnames(cor.dat1)[1:2]=c('Feature','Step'); cor.dat1=formatData(cor.dat1)
  cor.dat2=melt(cor.mat2); cor.dat2$Type=second;colnames(cor.dat2)[1:2]=c('Feature','Step'); cor.dat2=formatData(cor.dat2)
  cor.dat <- rbind(cor.dat1,cor.dat2)
  cor.dat <- data.frame(cor.dat)
  cor.dat$Featurelbl=factor(cor.dat$Featurelbl, levels=rev(levels(cor.dat$Featurelbl)))
  cor.dat <- cor.dat[-which(is.na(cor.dat[, 3])),]
  
  summary(cor.dat)
  
  ## Plotting    
  p=plot.correlation.matrix.stepwise(cor.dat,1.5)+
    facet_grid(FeatureType~Type,scales='free_y',space='free_y')
  return(p)
}
