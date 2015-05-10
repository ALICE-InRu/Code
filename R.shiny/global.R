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



