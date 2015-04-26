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
source('getFiles.R')
source('formatData.R')
source('myFigures.R')

sdrs=c('SPT','LPT','LWR','MWR');
rhoLabel=expression("Deviation from optimality," * ~ rho * ~ " (%)")

if(file.exists('startUp.Rdata')){ load('startUp.Rdata') } else {
  dataset.OPT=get.files.OPT()
  dataset.SDR=get.files.SDR()
  save(list=c('dataset.OPT','dataset.SDR'),file='startUp.Rdata')
}

