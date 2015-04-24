output$tabOpt.bw <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Following optimal trajectory',plotOutput('plot.stepwiseBestWorst.opt')),
      box(title='Following SDR trajectory',plotOutput('plot.stepwiseBestWorst.sdr'),
          helpText('Only main problem space considered.'))
    )
  )
})

output$plot.stepwiseBestWorst.opt <- renderPlot({
  withProgress(message = 'Plotting all problems', value = 0, {
    plot.BestWorst(input$problems,input$dimension,'OPT',input$save)
  })
})

output$plot.stepwiseBestWorst.sdr <- renderPlot({
  withProgress(message = 'Plotting all tracks', value = 0, {
    plot.BestWorst(input$problem,input$dimension,'ALL',input$save)
  })
})
