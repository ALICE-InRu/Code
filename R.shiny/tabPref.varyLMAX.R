source('global.R')
source('pref.settings.R')
source('pref.varyLMAX.R')
source('pref.imitationLearning.R')

input <- list(problem='j.rnd',dimension='10x10')

#for(dim in c('6x5','10x10')){
#  for(track in c('OPTEXT','ILUNSUPEXT')){
#    create.prefModel.varyLMAX(input$problem,dim,track,'p')
#  }
#}

CDR.lmax <- CDR.prefModel.varyLMAX(input$problem,input$dimension,'ILUNSUPEXT','p')
plot.prefModel.varyLMAX(CDR.lmax)
stats.lmax <- stats.prefModel.varyLMAX(CDR.lmax)
stats.lmax$Type = 'lmax'

CDR.il <- get.CDR.IL(input$problem,input$dimension)
stats.il <- stats.imitationLearning(CDR.il)
stats.il$lmax=sizePreferenceSet(input$dimension,F)
stats.il$Default=TRUE
stats.il$Type = 'il'

stat <- rbind(stats.lmax,stats.il)
stat <- arrange(stat, Training.Rho, Test.Rho) # order w.r.t. lowest mean

print(head(stat))
