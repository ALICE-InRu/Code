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
  problem=input$problem
  dim=input$dimension
  withProgress(message = 'Making plot', value = 0, {
    p=plot.StepwiseExtremal(dataset.StepwiseOptimality(),dataset.StepwiseExtremal(),F)
  })
  print(p)
},height="auto")

output$plot.global <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    p=plot.StepwiseFeatures(input$problem,input$dimension,F,T)+ggtitle('')
  })
  print(p)
},height="auto")

output$plot.local <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    p=plot.StepwiseFeatures(input$problem,input$dimension,T,F)+ggtitle('')
  })
  print(p)
},height="auto")
