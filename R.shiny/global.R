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
rhoLabel=expression("Deviation from optimality," * ~ rho * ~ " (%)")

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
