output$tabPref.exhaustive <- renderUI({
  dashboardBody(
    fluidRow(helpText('Using main problem distribution and preferably 10x10 dimension. Check settings to set trajectory used.')),
    fluidRow(
      box(title = "Pareto front", collapsible = TRUE, width=12,
          #tags$head( tags$script(src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML-full", type = 'text/javascript'),tags$script( "MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});", type='text/x-mathjax-config')),
          helpText('Scatter plot for validation accuracy (%) against its corresponding mean expected Rho (%) for all', choose(16,16)+choose(16,1)+choose(16,2)+choose(16,3), 'linear models, based on either one, two, three or all d combinations of features. Pareto fronts for each active feature count based on maximum validation accuracy and minimum mean expected Rho (%), and labelled with their model ID. Moreover, actual Pareto front over all models is marked with triangles.'),
          plotOutput("plot.exhaust.paretoFront", height = 250)
      ),
      box(title = "Training accuracy", collapsible = TRUE, width=12,
          helpText('Various methods of reporting validation accuracy for preference learning'),
          plotOutput("plot.exhaust.acc", height = 250)
      ),
      box(title = "Normalised weights", collapsible = TRUE, width=12,
          helpText('Normalised weights for CDR models, models are grouped w.r.t. its dimensionality, d. Note, a triangle indicates a solution on the Pareto front.'),
          plotOutput("plot.exhaust.paretoWeights", height = 250)
      ),
      box(title = "Stepwise optimality of dispatches", collapsible = TRUE, width=12,
          helpText('Probability of choosing optimal move for models corresponding to highest mean validation accuracy (grey) and lowest mean deviation from optimality, Rho, (black) compared to the baseline of probability of choosing an optimal move at random (dashed)'),
          plotOutput("plot.exhaust.bestAcc", height = 250)
      ),
      box(title = "Boxplot", collapsible = TRUE, width=12,
          helpText('Box plot for deviation from optimality, Rho, (%) for the best CDR models and compared against SDRs, both for training and test sets'),
          plotOutput("plot.exhaust.bestBoxplot", height = 250)
      ),
      box(title='Pareto front', collapsible=TRUE, width=12, tableOutput("table.exhaust.paretoFront")),
      box(title='Kolmogorov-Smirnov Tests', collapsible = TRUE, width=12, height=1000,
          helpText('p-values for two-sided Kolmogorov-Smirnov test. Only done for main problem distribution.'),
          box(title='w.r.t. Rho for training set', width=6, tableOutput("table.liblinearKolmogorov.Rho.train")),
          box(title='w.r.t. Rho for test set', width=6, tableOutput("table.liblinearKolmogorov.Rho.test")),
          box(title='w.r.t. training accuracy', width=6, tableOutput("table.liblinearKolmogorov.Acc"))
      )
    )
  )
})

prefSummary <- reactive({
  withProgress(message = 'Loading exhaustive data', value = 0, {
    get.prefSummary(input$problems,input$dimension,'OPT','p',input$bias,F)
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
    plot.exhaust.acc(prefSummary(),input$save)+themeVerticalLegend
    })
}, height="auto")

output$plot.exhaust.paretoWeights <- renderPlot({
  withProgress(message = 'Plotting Pareto weights', value = 0, {
    plot.exhaust.paretoWeights(paretoFront(),input$timedependent,input$save)
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
