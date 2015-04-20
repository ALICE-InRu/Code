rm(list=ls(all=TRUE))
library(shiny)
library(shinydashboard)
library(markdown)
library(ggplot2)
library(plyr)
library(knitr)
library(xtable)
library(grid)
source('getfiles.R')
source('formatData.R')
source('myFigures.R')

sdrs=c('SPT','LPT','LWR','MWR');
sdrNames=c('Shortest Processing Time','Largest Processing Time','Least Work Remaining','Most Work Remaining')
rhoLabel=expression("Deviation from optimality," * ~ rho * ~ " (%)")

if(file.exists('startUp.Rdata')){ load('startUp.Rdata')} else {
  dataset.OPT=getOPTs()
  all.dataset.SDR=getfiles('../SDR/')
  save(list=c('dataset.OPT','all.dataset.SDR'),file='startUp.Rdata')
}

