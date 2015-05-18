output$tabCMAES <- renderUI({
  dashboardBody(
    fluidRow(box(title='Settings', checkboxInput("timedependentCMA","Stepwise dependent:"))),
    fluidRow(
      box(title = "Box-plot", collapsible = TRUE, width=12,
          plotOutput("plot.CMABoxplot", height = 500),
          checkboxInput("CMAvsSDR","Compare with SDRs:")
      ),
      box(title = "Evolution of fitness", collapsible = TRUE, width=6,
          plotOutput("plot.evolutionCMA.Fitness", height = 500),
          helpText('MinimumRho and MinimumMakespan are depicted in gray and black, respectively.')
      ),
      box(title = "Evolution of weights", collapsible = TRUE, width=6,
          helpText("For main problem distribution"),
          plotOutput("plot.CMAWeights", height = 500)
      )
    )
  )
})

evolutionCMA <- reactive({
  withProgress(message = 'Loading CMA-ES results', value = 0, {
    get.evolutionCMA(input$problems,input$dimension)})
})

output$plot.CMAWeights <- renderPlot(
  if(input$timedependentCMA)
    plot.evolutionCMA.Weights(evolutionCMA(),input$problem)
  else
    plot.CMAPREF.timedependentWeights(input$problem, input$dimension)
)
output$plot.evolutionCMA.Fitness <- renderPlot(plot.evolutionCMA.Fitness(evolutionCMA()))

CDR.CMA <- reactive({
  withProgress(message = 'Loading CDR data', value = 0, {
    get.CDR.CMA(input$problems,input$dimension,input$timedependentCMA) })
})
output$plot.CMABoxplot <- renderPlot(
  if(input$CMAvsSDR)
    plot.CMABoxplot(CDR.CMA(),SDR())
  else
    plot.CMABoxplot(CDR.CMA())
)
