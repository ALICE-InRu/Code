server <- function(input, output, session) {

  source('optimalityOfDispatches.R')
  source('liblinear.R')

  source('tabSDR.R',local=T)
  source('tabOpt.R',local=T)
  source('tabFEAT.R',local=T)
  source('tabAbout.R',local=T)
  source('tabTable.R',local=T)
  source('tabPref.settings.R',local=T)
  source('tabPref.exhaustive.R',local=T)
  source('tabPref.imitationLearning.R',local=T)

  observe({
    lvs = levels(droplevels(subset(dataset.OPT,Dimension==input$dimension))$Problem)
    updateSelectInput(session, "problems", choices =  lvs, selected = lvs[1])
  })
}
