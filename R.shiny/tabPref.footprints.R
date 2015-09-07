output$tabFootprint <- renderUI({
  dashboardBody(
    fluidRow(
      box(width=6, collapsible = T,
          ),
      box(width = 12, plotOutput("plot.correlation.sdr")),
      box(width = 12, plotOutput("plot.correlation.all")),
      box(width = 12, dataTableOutput("stats.correlation"))
    )
  )
})


footprint.dat <- reactive({
  withProgress(message = 'Retrieving data', value = 0, {
    trdat <- get.files.TRDAT(input$problem, input$dimension, 'ALL', useDiff = F)
    trdat <- subset(trdat,Followed==T)

    quartiles <- dataset.diff()$Quartiles

    trdat.lbl=labelDifficulty(subset(trdat,Step==max(trdat$Step)-1), # might be missing last step
                              quartiles)
    trdat.lbl$FinalRho = trdat.lbl$Rho
    trdat <- merge(trdat,trdat.lbl[,c('Problem','Track','PID','FinalRho','Difficulty')],
                   by=c('Problem','Track','PID'))
    trdat <- trdat[,grep('Track|PID|Step|phi|Difficulty|Rho',colnames(trdat))]
    trdat$Rho=NULL
  })
  return(trdat)
})

output$plot.correlation.sdr <- renderPlot({
  corr.rho <- do.call(rbind, lapply(sdrs[1:4], function(sdr) {
    df <- correlation.matrix.stepwise(subset(trdat,Track==sdr),'FinalRho',input$Bonferroni)
    df$Track = sdr
    return(df) } ))
  plot.correlation.matrix.stepwise(corr.rho)
})

output$plot.correlation.all <- renderPlot({
  corr.rho <- correlation.matrix.stepwise(trdat,'FinalRho')
  corr.rho$Track='ALL'
  plot.correlation.matrix.stepwise(corr.rho)+facet_grid(Track~Difficulty)
})

output$stats.correlation <- renderTable({

})
