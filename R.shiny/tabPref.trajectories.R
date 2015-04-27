output$tabPref.trajectories <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Settings', collapsible = T,
          helpText('For main problem distribution.'),
          selectInput("plotTracks", "Trajectories:", multiple = T,
                      c("OPT",sdrs,"RND","ALL"), selected = c("OPT",sdrs,"RND","ALL")),
          selectInput("plotRanks", "Rankings:", multiple = T,
                      c("p","f","b","a"), selected=c("p","f","b","a"))
      )
    ),
    fluidRow(
      box(title='Size of training set', width=6,
          plotOutput('plot.trainingDataSize', height=500)),
      box(title='Size of preference set', width=6,
          plotOutput('plot.preferenceSetSize', height=500)),
      box(title='Boxplot', width=12,
          plotOutput('plot.rhoTracksRanks', height=500),
          checkboxInput('plotSDR','Display the trajectories the models are based on (white).', T)),
      box(title='Summary for Rho', width=9,
          tableOutput('table.rhoTracksRanks'))
    )
  )
})

trainingDataSize <- reactive({ get.trainingDataSize(input$problem,input$dimension) })

output$plot.trainingDataSize <- renderPlot({
  withProgress(message = 'Plotting training set size', value = 0, {
    plot.trainingDataSize(
      subset(trainingDataSize(), Track %in% input$plotTracks))
  })
})

preferenceSetSize <- reactive({ get.preferenceSetSize(input$problem,input$dimension) })

output$plot.preferenceSetSize <- renderPlot({
  withProgress(message = 'Plotting preference set size', value = 0, {
    plot.preferenceSetSize(
      subset(preferenceSetSize(),
             Track %in% input$plotTracks & Rank %in% input$plotRanks))
  })
})

rhoTracksRanks <- reactive({ get.rhoTracksRanks(input$problem,input$dimension) })

output$plot.rhoTracksRanks <- renderPlot({
  withProgress(message = 'Plotting boxplot', value = 0, {
    SDR=switch(input$plotSDR, T=SDR())
    plot.rhoTracksRanks(subset(rhoTracksRanks(),
                               Track %in% input$plotTracks & Rank %in% input$plotRanks), SDR)
  })
})

output$table.rhoTracksRanks <- renderTable({
  SDR=switch(input$plotSDR, T=SDR())
  table.rhoTracksRanks(input$problem, subset(rhoTracksRanks(),
                             Track %in% input$plotTracks & Rank %in% input$plotRanks), SDR)
}, include.rownames = FALSE)
