output$tabFEAT <- renderUI({
  dashboardBody(
    fluidRow(
      box(title="Extremal", plotOutput("plot.extremal", height=600)),
      box(title="Evolution of features",
          plotOutput("plot.local", height=300),
          plotOutput("plot.global", height=300))
    )
  )
})

output$plot.extremal <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    plot.StepwiseExtremal(dataset.StepwiseOptimality(),dataset.StepwiseExtremal(),F)
  })
},height="auto")

output$plot.global <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    plot.StepwiseFeatures(input$problem,input$dimension,F,T)+ggtitle('')
  })
},height="auto")

output$plot.local <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    plot.StepwiseFeatures(input$problem,input$dimension,T,F)+ggtitle('')
  })
},height="auto")
