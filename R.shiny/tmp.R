source('global.R')
input=list(problem='j.rnd',dimension='6x5')

source('sdr.R')
quartiles <- get.quartiles(subset(dataset.SDR, Set=='train' & Dimension==input$dimension & Problem==input$problem))

trdat <- get.files.TRDAT(input$problem, input$dimension, 'ALL', useDiff = F)
trdat <- subset(trdat,Followed==T)

trdat.lbl=labelDifficulty(subset(trdat,Step==max(trdat$Step)-1),quartiles) # might be missing last step
trdat.lbl$FinalRho = trdat.lbl$Rho
trdat <- merge(trdat,trdat.lbl[,c('Problem','Track','PID','FinalRho','Difficulty')], by=c('Problem','Track','PID'))
trdat <- trdat[,grep('Track|PID|Step|phi|Difficulty|Rho',colnames(trdat))]
trdat$Rho=NULL

source('feat.footprints.R')
corr.rho <- do.call(rbind, lapply(sdrs[1:4], function(sdr) {
  df <- correlation.matrix.stepwise(subset(trdat,Track==sdr),'FinalRho',F)
  df$Track = sdr
  return(df) } ))

plot.correlation.matrix.stepwise(corr.rho)

corr.rho <- correlation.matrix.stepwise(trdat,'FinalRho')
corr.rho$Track='ALL'
plot.correlation.matrix.stepwise(corr.rho)+facet_grid(Track~Difficulty)

ks.dat <- ks.matrix.stepwise(trdat,bonferroniAdjust = F)
plot.stepwise.test(ks.dat)
