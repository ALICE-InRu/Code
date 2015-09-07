server <- function(input, output, session) {

  source('tabSDR.R', local=T); source('sdr.R', local = T)
  source('tabOpt.uniqueness.R', local=T); source('opt.uniqueness.R', local = T)
  source('tabOpt.SDR.R', local=T); source('opt.SDR.R', local = T)
  source('tabOpt.bw.R', local=T); source('opt.bw.R', local = T)
  source('tabFeat.R', local=T); source('feat.R', local =T)
  source('tabTable.R', local=T)
  source('tabPref.settings.R', local=T); source('pref.settings.R', local=T)
  source('pref.varyLMAX.R', local=T);
  source('tabPref.trajectories.R', local=T); source('pref.trajectories.R', local=T)
  source('tabPref.stepwiseBias.R',local=T); source('pref.stepwiseBias.R', local=T)
  source('tabPref.exhaustive.R', local=T); source('pref.exhaustive.R', local=T)
  source('tabPref.imitationLearning.R', local=T); source('pref.imitationLearning.R', local=T); fixUnsupIL();
  source('tabGantt.R', local=T); source('gantt.R', local=T)
  source('tabCMAES.R', local=T); source('cmaes.R', local=T)
  source('tabAbout.R', local=T)
  source('tabFeat.footprints.R', local=T); source('feat.footprints.R')

  observe({
    lvs = levels(droplevels(subset(dataset.OPT,Dimension==input$dimension))$Problem)
    updateSelectInput(session, "problems", choices =  lvs, selected = lvs)
  })
  observe({
    updateSelectInput(session, "problem", choices =  input$problems)
  })

}
