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
    trdat <- subset(all.trdat(),Followed==T)
    quartiles <- dataset.diff()$Quartiles
    label.trdat(trdat,quartiles)
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
