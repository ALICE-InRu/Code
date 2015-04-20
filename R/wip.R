setwd('C:/Users/helga/alice/Code/R/')
library(ggplot2)
library(reshape)

plot <- function(fname){
  print(fname)
  distr=strsplit(strsplit(fname,'.user')[[1]][1],'//')[[1]][2]

  LPT <- read.csv(paste('../SDR/',distr,'.LPT.csv',sep=''))
  LPT = subset(LPT,Dimension == 100 & Set == 'train')
  SPT <- read.csv(paste('../SDR/',distr,'.SPT.csv',sep=''))
  SPT = subset(SPT,Dimension == 100 & Set == 'train')
  LWR <- read.csv(paste('../SDR/',distr,'.LWR.csv',sep=''))
  LWR = subset(LWR,Dimension == 100 & Set == 'train')
  MWR <- read.csv(paste('../SDR/',distr,'.MWR.csv',sep=''))
  MWR = subset(MWR,Dimension == 100 & Set == 'train')
    
  PREF = read.csv(fname)
  PREF = subset(PREF, Set=='train' & Dimension==100)  
  
  dat = data.frame('PID'=LPT$PID, 'LPT'=LPT$Rho, 'SPT'=SPT$Rho, 'LWR'=LWR$Rho, 'MWR'=MWR$Rho, 'PREF'=PREF$Rho)
  dat = subset(dat,PID <=  500)
  
  mdat <- melt(dat, id.vars = 'PID')
  ggplot(mdat, aes(x=variable, y=value,fill=variable))+geom_boxplot()+ggtitle(fname)
}

