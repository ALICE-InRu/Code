output$tabOpt.uniqueness <- renderUI({
  dashboardBody(
    fluidRow(box(title='Settings',collapsible = T, checkboxInput('smooth', 'Smooth'))),
    fluidRow(
      box(title='Uniqueness of optimal solutions',plotOutput('plot.stepwiseUniqueness')),
      box(title='Optimality of solutions',plotOutput('plot.stepwiseOptimality'))
    )
  )
})

all.dataset.StepwiseOptimality <- reactive({
  withProgress(message = 'Loading all stepwise data', value = 0, {
    get.StepwiseOptimality(input$problems,input$dimension,'OPT')
  })
})

output$plot.stepwiseUniqueness <- renderPlot({
  withProgress(message = 'Ploting stepwise uniqueness', value = 0, {
    plot.stepwiseUniqueness(all.dataset.StepwiseOptimality(),input$dimension,input$smooth,input$save)
  })
}, height="auto")

output$plot.stepwiseOptimality <- renderPlot({
  withProgress(message = 'Plotting stepwise optimality', value = 0, {
    plot.stepwiseOptimality(all.dataset.StepwiseOptimality(),input$dimension,F,input$smooth,input$save)
  })
}, height="auto")

