output$tabPref.imitationLearning <- renderUI({
  dashboardBody(
    fluidRow(
      # A static valueBox
      valueBox("Iterations", "Imitation learning", icon = icon("recycle"), width = 3),
      # Dynamic valueBoxes
      valueBoxOutput("progressBoxUnsup", width = 3),
      valueBoxOutput("progressBoxSup", width = 3),
      valueBoxOutput("progressBoxFixsup", width = 3)
    ),
    fluidRow(helpText('Using main problem distribution...')),
    fluidRow(
      box(width = 6, plotOutput("compareImitationLearning.boxplot")),
      box(width = 6, plotOutput("compareImitationLearning.weights")),
      box(width = 12, dataTableOutput("compareImitationLearning.stats"))
    )
  )
})

output$progressBoxSup <- renderValueBox({
  files = getSummaryFileNamesIL(input$problem,input$dimension)
  valueBox( paste0('#',sum(grepl('[0-9]+SUP',files))), "Decreased supervision", color = "purple", icon = icon("eye"))
})
output$progressBoxUnsup <- renderValueBox({
  files = getSummaryFileNamesIL(input$problem,input$dimension)
  valueBox( paste0('#',sum(grepl('[0-9]+UNSUP',files))), "Unsupervised", color = "yellow", icon = icon("eye-slash"))
})
output$progressBoxFixsup <- renderValueBox({
  files = getSummaryFileNamesIL(input$problem,input$dimension)
  valueBox( paste0('#',sum(grepl('[0-9]+FIXSUP',files))), "Fixed supervision", color = "maroon", icon = icon("eyedropper"))
})

output$compareImitationLearning.boxplot <- renderPlot({
  withProgress(message = 'Plotting boxplot', value = 0, {
    plot.imitationLearning.boxplot(input$problem,input$dimension)
  })
})

output$compareImitationLearning.weights <- renderPlot({
  withProgress(message = 'Plotting weights', value = 0, {
    plot.imitationLearning.weights(input$problem,input$dimension)
  })
})

output$compareImitationLearning.stats <- renderDataTable({
  withProgress(message = 'Summary table', value = 0, {
    stats.imitationLearning(input$problem,input$dimension)
  })
},  options = list(paging = FALSE, searching = T))
