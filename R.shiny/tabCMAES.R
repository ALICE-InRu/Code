output$tabCMAES <- renderUI({
  dashboardBody(
    fluidRow(
      box(title = "Settings", collapsible = TRUE, width=6,
          checkboxInput("onlyMainCMAES","Only display main problem space", value=T)
      )
    ),
    fluidRow(
      box(title = "Deviation from optimality", collapsible = TRUE, width=12,
          plotOutput("plot.CMABoxplot", height = 500),
          tableOutput("stat.CMABoxplot"),
          checkboxInput("CMAvsSDR","Compare with SDRs for main problem"),
          checkboxInput("CMAforORLIB","Test on OR-Library benchmark set")
      )),
    fluidRow(
      box(title = "Evolution of fitness", collapsible = TRUE, width=12,
          plotOutput("plot.evolutionCMA.Fitness", height = 500),
          tableOutput("stat.evolutionCMA.Fitness")
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
output$stat.evolutionCMA.Fitness <- renderTable({
  last.evolutionCMA(evolutionCMA())
}, include.rownames=F)

CDR.CMA.all <- reactive({
  withProgress(message = 'Loading CDR data', value = 0, {
    if(input$CMAforORLIB)
      get.CDR.CMA(input$problems,input$dimension,times = F, testProblems = 'ORLIB')
    else
      get.CDR.CMA(input$problems,input$dimension) })
})
CDR.CMA <- reactive({
  if(input$CMAvsSDR|input$onlyMainCMAES)
    subset(CDR.CMA.all(),Problem == input$problem)
  else
    CDR.CMA.all()
})
SDR.CMA <- reactive({
  if(input$CMAvsSDR)
    subset(SDR(),Problem == input$problem)
  else
    NULL
})

output$plot.CMABoxplot <- renderPlot(
  withProgress(message = 'Plotting boxplot', value = 0, {
      plot.CMABoxplot(CDR.CMA(),SDR.CMA())
  })
)
output$stat.CMABoxplot <- renderTable({
  if(input$CMAforORLIB) {
    vars=c('Problem','TrainingData','Timedependent','ObjFun')
  } else {vars=c('Problem','Dimension','Timedependent','ObjFun')}
  stat=ddply(subset(CDR.CMA(),!is.na(Rho)),vars,function(x) summary(x$Rho))
  stat$Problem <- factorProblem(stat,F)
  stat=arrange(stat,Dimension,Problem,ObjFun,Timedependent)
  xtable(stat)
},include.rownames = F)
