output$tabPref.exhaustive <- renderUI({
  dashboardBody(
    fluidRow(helpText('Using main problem distribution')),
    fluidRow(column(6, selectInput('exhaustBias','Bias',c('equal','adjdbl2nd'))),
             column(6, selectInput('exhaustTrack','Track',c('OPT','CMAESMINCMAX')))
             ),
    fluidRow(
      box(title = "Pareto front", collapsible = TRUE, width=6,
          plotOutput("plot.exhaust.paretoFront", height = 250)
      ),
      box(title = "Training accuracy", collapsible = TRUE, width=6,
          plotOutput("plot.exhaust.acc", height = 250)
      ),
      box(title = "Normalised weights", collapsible = TRUE, width=6,
          plotOutput("plot.exhaust.paretoWeights", height = 300)
      ),
      box(title = "Stepwise optimality of dispatches", collapsible = TRUE, width=6,
          plotOutput("plot.exhaust.bestAcc", height = 300)
      ),
      box(title = "Boxplot", collapsible = TRUE, width=6,
          plotOutput("plot.exhaust.bestBoxplot", height = 250)
      ),
      box(title='Pareto front', collapsible=TRUE, width=6,
          tableOutput("table.exhaust.paretoFront"))
#      ,
#      box(title='Kolmogorov-Smirnov Tests', collapsible = TRUE, width=12, height=1000,
#          helpText('H0: Models are drawn  drawn from the same continuous distribution.',
#                   'K-S test p-values for main problem distribution.'),
#          #box(title='Training set', width=6, plotOutput("plot.liblinearKolmogorov.train")),
#          #box(title='Test set', width=6, plotOutput("plot.liblinearKolmogorov.test")))
#          box(title='w.r.t. Rho for training set', width=6, tableOutput("table.liblinearKolmogorov.Rho.train")),
#          box(title='w.r.t. Rho for test set', width=6, tableOutput("table.liblinearKolmogorov.Rho.test")),
#          box(title='w.r.t. training accuracy', width=6, tableOutput("table.liblinearKolmogorov.Acc"))
#)
    )
  )
})

prefSummary <- reactive({
  withProgress(message = 'Loading exhaustive data', value = 0, {
    get.prefSummary(input$problem,input$dimension,input$exhaustTrack,'p',F,
                    bias=input$exhaustBias)
  })
})

paretoFront <- reactive({
  withProgress(message = 'Finding Pareto front', value = 0, {
    get.paretoFront(prefSummary())
  })
})

output$plot.exhaust.paretoFront <- renderPlot({
  withProgress(message = 'Plotting Pareto front', value = 0, {
    plot.exhaust.paretoFront(prefSummary(),paretoFront())
  })
})

output$plot.exhaust.acc <- renderPlot({
  withProgress(message = 'Plotting training acc.', value = 0, {
    plot.exhaust.acc(prefSummary(),input$save,bestPrefModel()$Summary)+themeVerticalLegend
    })
}, height="auto")

output$plot.exhaust.paretoWeights <- renderPlot({
  withProgress(message = 'Plotting Pareto weights', value = 0, {
    plot.exhaust.paretoWeights(paretoFront(),input$save)
  })
}, height="auto")

bestPrefModel <- reactive({
  withProgress(message = 'Finding best models', value = 0, {
    get.bestPrefModel(paretoFront())
  })
})

output$plot.exhaust.bestAcc <- renderPlot({
  withProgress(message = 'Plotting accuracy', value = 0, {
    plot.exhaust.bestAcc(all.dataset.StepwiseOptimality(),bestPrefModel())+themeVerticalLegend
  })
}, height="auto")

output$plot.exhaust.bestBoxplot <- renderPlot({
  withProgress(message = 'Plotting boxplot', value = 0, {
    plot.exhaust.bestBoxplot(bestPrefModel(), SDR())+themeVerticalLegend
  })
}, height="auto")

output$table.exhaust.paretoFront <- renderTable({
  table.exhaust.paretoFront(paretoFront())
}, include.rownames=FALSE, sanitize.text.function=function(x){x})

pareto.ks <- reactive({
  withProgress(message = 'Applying ks.test', value = 0, {
    suppressWarnings(get.pareto.ks(paretoFront(),input$problem, onlyPareto = F, SDR=NULL))
  })
})

output$table.liblinearKolmogorov.Rho.train <- renderTable({
  ks=pareto.ks()
  if(is.null(ks)){return(NULL)}
  return(ks$Rho.train)
},sanitize.text.function=function(x){x})

output$table.liblinearKolmogorov.Rho.test <- renderTable({
  ks=pareto.ks()
  if(is.null(ks)){return(NULL)}
  return(ks$Rho.test)
},sanitize.text.function=function(x){x})
output$table.liblinearKolmogorov.Acc <- renderTable({
  ks=pareto.ks()
  if(is.null(ks)){return(NULL)}
  return(ks$Acc)
},sanitize.text.function=function(x){x})


output$plot.liblinearKolmogorov.train <- renderPlot({
  ks=pareto.ks()
  if(is.null(ks)){return(NULL)}
  return(plot.ks.test2(ks$Rho.train,ks$Acc))
})

output$plot.liblinearKolmogorov.test <- renderPlot({
  ks=pareto.ks()
  if(is.null(ks)){return(NULL)}
  return(plot.ks.test2(ks$Rho.test))
})
