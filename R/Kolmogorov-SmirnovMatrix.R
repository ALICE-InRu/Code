ks.matrix <- function(df,split)
{
  splitCol = df[,grep(split,colnames(df))]
  names=unique(splitCol)
  if(length(names)<2){return(NULL)}
  
  df1 <- df[df[,split]==names[1],];df1[,split]<-NULL
  df2 <- df[df[,split]==names[2],];df2[,split]<-NULL
  
  ## Computing the Kolmogorov Smirnov p-valus matrix  
  
  ks.matrix=matrix(nrow=ncol(df1),ncol=ncol(df2))
  rownames(ks.matrix)=colnames(df1)
  colnames(ks.matrix)=colnames(df2)
  
  for(c1 in 1:ncol(df1)){
    for(c2 in 1:ncol(df2)){      
      ks.matrix[c1,c2]=ks.test(df1[,c1], df2[,c2])$p.value
    }
  }

  ks.matrix <- round(ks.matrix, digits = 2)
  ks.matrix
 
  return(ks.matrix)
}  

plot.ks.matrix <- function(ks.matrix, lbls){
  
  ## Turning it all into a dataframe and removing duplicates
  library(reshape)
  
  ks.dat <- melt(ks.matrix)
  ks.dat <- data.frame(ks.dat)
  
  levels(ks.dat$X2) <- rev(levels(ks.dat$X1))
    
  ks.dat
    
  ## Plotting
  library(ggplot2)
    
  theme_set(theme_bw())
  
  p=ggplot(ks.dat, aes(X2, X1, fill = value)) + 
    geom_tile() + 
    geom_text(aes(X2, X1, label = value), color = "#073642", size = 4) +
    scale_fill_gradient(name=expression('Kolmogorov-Smirnov p-values'), low = "#fdf6e3", high = "steelblue", breaks=seq(0, 1, by = 0.2), limits = c(0.3, 1)) +
    scale_x_discrete(expand = c(0, 0)) +
    scale_y_discrete(expand = c(0, 0)) +
    labs(x = "", y = "") +
    guides(fill = guide_colorbar(barwidth = 7, barheight = 1, title.position = "top", title.hjust = 0.5)) + theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1), 
          panel.grid.major = element_blank(),
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.ticks = element_blank(),
          legend.justification = 'center',
          legend.position = 'top',
          legend.direction = "horizontal") +
    guides(fill = guide_colorbar(barwidth = 7, barheight = 1, title.position = "top", title.hjust = 0.5))  
  p = p + xlab(sprintf('%s (#%d)',lbls[1,1], lbls$cnt[1]))+ylab(sprintf('%s (#%d)',lbls[2,1], lbls$cnt[2]))
  return(p)
}