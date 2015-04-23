if(Sys.info()['user']=="hei2"){  setwd('~/alice/Code/R')  
} else if(Sys.info()['user']=="helga"){ setwd('C:/Users/Helga/alice/Code/R') }

rm(list=ls(all=TRUE))
setwd('../R.shiny/')
source('global.R')
source('getfiles.R')
source('formatData.R')
source('myFigures.R')
setwd('../R/')

if(file.exists('startUp.Rdata')){ load('startUp.Rdata')} else {
  OPT=getOPTs() 
  SDR=getfiles('../SDR/')
  save(list=c('OPT','SDR'),file='startUp.Rdata')
}

problems.6x5=c('j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc')
problems.10x10=c('j.rnd','j.rndn','f.rnd')

clc()