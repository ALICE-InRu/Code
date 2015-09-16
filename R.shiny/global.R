rm(list=ls(all=TRUE))
library(shiny)
library(shinydashboard)
library(markdown)
library(ggplot2)
library(plyr)
library(knitr)
library(xtable)
library(grid)
library(reshape2)
library(readr)
library(gtable)
source('getFiles.R')
source('formatData.R')
source('myFigures.R')
DataDir = '../../Data/'

sdrs=c('SPT','LPT','LWR','MWR','RND');

dataset.OPT=get.files.OPT()
dataset.SDR=get.files.SDR()

ks.test2 <- function(x1,x2,alpha=0.05){
  # H = KSTEST2(X1,X2) performs a Kolmogorov-Smirnov (K-S) test
  # to determine if independent random samples, X1 and X2, are drawn from the
  # same underlying continuous population. H indicates the result of the hypothesis test:
  #       H = 0 => Do not reject the null hypothesis at the 5% significance level.
  #       H = 1 => Reject the null hypothesis at the 5% significance level.
  pValue <- ks.test(x1,x2)$p
  H  =  (alpha >= pValue)
  return(H)
}

plot.ks.test2 <- function(p.rho, p.acc=NULL, alpha=0.05){

  H.rho = alpha >= p.rho
  mdat <- melt(H.rho)
  mdat$Type = 'Rho'

  if(!is.null(p.acc)){
    H.acc = alpha >= p.acc
    tmp = melt(H.acc)
    tmp$Type = 'Acc'
    mdat = rbind(mdat,tmp)
    mdat$Type <- factor(mdat$Type, levels=c('Rho','Acc'))
  }

  p <- ggplot(subset(mdat,!is.na(value)), aes(x=factor(Var2),y=factor(Var1))) +
    geom_tile(fill='white',color='black')+
    geom_point(data=subset(mdat, value==T), aes(shape=Type)) + scale_shape_manual('Reject',values=c(3,4)) +
    xlab(NULL)+ylab(NULL)+
    theme_bw() +
    theme(axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks=element_blank(),
          panel.border=element_blank(),
          legend.position="bottom") +
    annotate("text", x = (1:nrow(H.rho)), y = 1:nrow(H.rho), label = rownames(H.rho))

  return(p)

}
