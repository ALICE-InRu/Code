output$tabOpt.SDR <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='SDR optimality w.r.t. trajectory', width=12,
          plotOutput('plot.stepwiseSDR.wrtTrack'))
    )
  )
})

dataset.StepwiseOptimality <- reactive({
  withProgress(message = 'Loading optimal data', value = 0, {
    get.StepwiseOptimality(input$problem,input$dimension,'OPT')
  })
})

dataset.StepwiseExtremal <- reactive({
  withProgress(message = 'Loading extremal data', value = 0, {
    get.StepwiseExtremal(input$problem,input$dimension)
  })
})

output$plot.stepwiseSDR.wrtTrack <- renderPlot({
  withProgress(message = 'Making plotStepwiseSDR.wrtTrack', value = 0, {
    plot.StepwiseSDR.wrtTrack(dataset.StepwiseOptimality(),dataset.StepwiseExtremal(),input$dimension,F,input$save)
  })
}, height='auto')
