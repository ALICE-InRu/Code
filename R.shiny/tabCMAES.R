output$tabCMAES <- renderUI({
  dashboardBody(
    fluidRow(
      box(title = "Settings", collapsible = TRUE, width=6,
          checkboxInput("onlyMainCMAES","Only display main problem space", value=T)
      )
    ),
    fluidRow(
      box(title = "Box-plot", collapsible = TRUE, width=6,
          plotOutput("plot.CMABoxplot", height = 500),
          checkboxInput("CMAvsSDR","Compare with SDRs for main problem")
      ),
      box(title = "Evolution of fitness", collapsible = TRUE, width=6,
          plotOutput("plot.evolutionCMA.Fitness", height = 500)
      )),
    fluidRow(
      box(title = "Evolution of time independent weights over genaration",
          collapsible = TRUE, width=6,
          plotOutput("plot.CMAWeights.timeindependent", height = 500)
      ),
      box(title = "Evolution of time dependent weights over dispatch iterations",
          collapsible = TRUE, width=6,
          plotOutput("plot.CMAWeights.timedependent", height = 500)
      )
    )
  )
})

evolutionCMA.all <- reactive({
  withProgress(message = 'Loading CMA-ES results', value = 0, {
    get.evolutionCMA(input$problems,input$dimension)})
})

evolutionCMA <- reactive({
  if(input$onlyMainCMAES)
    subset(evolutionCMA.all(), Problem == input$problem)
  else
    evolutionCMA.all()
})

output$plot.CMAWeights.timedependent <- renderPlot(
  withProgress(message = 'Plotting time dependent weights', value = 0, {
    plot.evolutionCMA.Weights(evolutionCMA(),T)
  })
)
output$plot.CMAWeights.timeindependent <- renderPlot(
  withProgress(message = 'Plotting time independent weights', value = 0, {
    plot.evolutionCMA.Weights(evolutionCMA(),F)
  })
)

output$plot.evolutionCMA.Fitness <- renderPlot(
  withProgress(message = 'Plotting fitness', value = 0, {
    plot.evolutionCMA.Fitness(evolutionCMA())
  })
)

CDR.CMA <- reactive({
  withProgress(message = 'Loading CDR data', value = 0, {
    get.CDR.CMA(input$problems,input$dimension) })
})
output$plot.CMABoxplot <- renderPlot(
  withProgress(message = 'Plotting boxplot', value = 0, {
    if(input$CMAvsSDR)
      plot.CMABoxplot(subset(CDR.CMA(),Problem == input$problem),
                      subset(SDR(),Problem == input$problem))
    else if(input$onlyMainCMAES)
      plot.CMABoxplot(subset(CDR.CMA(),Problem == input$problem))
    else
      plot.CMABoxplot(CDR.CMA())
  })
)
