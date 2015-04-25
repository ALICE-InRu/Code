output$tabPref.trajectories <- renderUI({
  dashboardBody(
    fluidRow(
      box(plotOutput('plot.trainingDataSize', height=500)),
      box(plotOutput('plot.preferenceSetSize', height=500))
    )
  )
})

trainingDataSize <- reactive({
  get.trainingDataSize(input$problems,input$dimension,'ALL')
})

output$plot.trainingDataSize <- renderPlot({
  withProgress(message = 'Plotting training set size', value = 0, {
    plot.trainingDataSize(trainingDataSize())
  })
})

preferenceSetSize <- reactive({
  get.preferenceSetSize(input$problems,input$dimension,'ALL',c('b','f','p','a'))
})

output$plot.preferenceSetSize <- renderPlot({
  withProgress(message = 'Plotting preference set size', value = 0, {
    plot.preferenceSetSize(preferenceSetSize())
  })
})
