correlation.matrix <- function(df, method = 'spearman')
{
  # Based on: http://www.peterhaschke.com/r/2013/04/23/CorrelationMatrix.html
    
  ## Computing the correlation matrix
  cor.matrix <- round(cor(df, use = "pairwise.complete.obs", method = method), digits = 2)
  cor.matrix
  
  ## Setting duplicates to NA and taking the absolute value
  for(row in 2:nrow(cor.matrix)){  cor.matrix[row,1:row-1] <- NA }
  
  cor.matrix <- abs(cor.matrix)
  cor.matrix
  
  ## Turning it all into a dataframe and removing duplicates
  library(reshape)

  cor.dat <- melt(cor.matrix)
  cor.dat <- cor.dat[-which(is.na(cor.dat[, 3])),]
  cor.dat <- data.frame(cor.dat)
  cor.dat

  ## Renaming the variables and ordering the dataframe
  library(reshape)
  if(TRUE){
    renamed=list("Miles per Gallon" = "mpg", "# of Cylinders" = "cyl", "Displacement" = "disp", "Horsepower" = "hp", "Weight" = "wt", "# of Gears" = "gear")  
  } else {  
    #FIX ME 
  }

  levels(cor.dat$X1) <- renamed
  levels(cor.dat$X2) <- rev(renamed)

  ## Plotting
  library(ggplot2)
  #library(ggthemes);  theme_set(theme_solarized())
  
  theme_set(theme_bw())

  p=ggplot(cor.dat, aes(X2, X1, fill = value)) + 
    geom_tile() + 
    geom_text(aes(X2, X1, label = value), color = "#073642", size = 4) +
    scale_fill_gradient(name=expression("Spearman" * ~ rho), low = "#fdf6e3", high = "steelblue", breaks=seq(0, 1, by = 0.2), limits = c(0.3, 1)) +
    scale_x_discrete(expand = c(0, 0)) +
    scale_y_discrete(expand = c(0, 0)) +
    labs(x = "", y = "") + 
    guides(fill = guide_colorbar(barwidth = 7, barheight = 1, title.position = "top", title.hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1), 
          panel.grid.major = element_blank(),
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.ticks = element_blank(),
          legend.justification = c(1, 0),
          legend.position = c(0.9, 0.7),
          legend.direction = "horizontal") +
    guides(fill = guide_colorbar(barwidth = 7, barheight = 1, title.position = "top", title.hjust = 0.5))
  return(p)
}

## The Data (Motor Trend Car Road Tests)
#data(mtcars)
#dat <- with(mtcars, data.frame(mpg, cyl, disp, hp, wt, gear))
#summary(dat)
#p = correlation.matrix(dat)
#print(p)