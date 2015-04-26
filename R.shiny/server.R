server <- function(input, output, session) {

  source('tabSDR.R', local=T); source('sdr.R', local = T)
  source('tabOpt.uniqueness.R', local=T); source('opt.uniqueness.R', local = T)
  source('tabOpt.SDR.R', local=T); source('opt.SDR.R', local = T)
  source('tabOpt.bw.R', local=T); source('opt.bw.R', local = T)
  source('tabFeat.R', local=T); source('feat.R', local =T)
  source('tabTable.R', local=T)
  source('tabPref.settings.R', local=T); source('pref.settings.R', local=T)
  source('tabPref.trajectories.R', local=T); source('pref.trajectories.R', local=T)
  source('tabPref.exhaustive.R', local=T); source('pref.exhaustive.R', local=T)
  source('tabPref.imitationLearning.R', local=T); source('pref.imitationLearning.R', local=T)
  source('tabGantt.R', local=T); source('gantt.R', local=T)
  source('tabAbout.R', local=T)

  observe({
    lvs = levels(droplevels(subset(dataset.OPT,Dimension==input$dimension))$Problem)
    updateSelectInput(session, "problems", choices =  lvs, selected = lvs[1])
  })

}
