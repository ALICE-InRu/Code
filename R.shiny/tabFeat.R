output$tabFEAT <- renderUI({
  dashboardBody(
    fluidRow(
      box(title="Extremal", plotOutput("plot.extremal", height=600)),
      box(title="Evolution of features", plotOutput("plot.evol", height=600)),
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

output$plot.evol <- renderPlot({
  withProgress(message = 'Making plot', value = 0, {
    p=plot.StepwiseEvolution(input$problem,input$dimension)
    print(p)
  })
},height="auto")
