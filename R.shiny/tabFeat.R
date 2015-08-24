output$tabFEAT <- renderUI({
  dashboardBody(
    fluidRow(
      box(title="Extremal", plotOutput("plot.extremal", height=600)),
      box(title="Evolution of features",
          plotOutput("plot.local", height=300),
          plotOutput("plot.global", height=300)),
      box(width = 12, dataTableOutput("stats.singleFeat"))
    )
  )
})

dataset.singleFeat <- reactive({
  get.SingleFeat.CDR(input$problem, input$dimension)
})

output$stats.singleFeat <- renderDataTable({
  withProgress(message = 'Summary table', value = 0, {
    stats.singleFeat(dataset.singleFeat())
  })
},  options = list(paging = FALSE, searching = T))

output$plot.extremal <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    plot.StepwiseExtremal(dataset.StepwiseOptimality(),dataset.StepwiseExtremal(),dataset.singleFeat(),input$dimension,F)
  })
},height="auto")

output$plot.global <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    p=plot.StepwiseFeatures(input$problem,input$dimension,F,T)
    if(!is.null(p)){p=p+ggtitle('')}
    print(p)
  })
},height="auto")

output$plot.local <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    p=plot.StepwiseFeatures(input$problem,input$dimension,T,F)
    if(!is.null(p)){p=p+ggtitle('')}
    print(p)
  })
},height="auto")
