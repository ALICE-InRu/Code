output$tabPref.trajectories <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Settings', collapsible = T,
          helpText('For main problem distribution.'),
          selectInput("plotTracks", "Trajectories:", multiple = T,
                      c("OPT",sdrs,"RND","ALL","CMA-ES"), selected = c("OPT",sdrs,"RND","ALL","CMA-ES")),
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

all.rhoTracksRanks <- reactive({
  file_list <- get.CDR.file_list(input$problems,input$dimension,c(sdrs,'ALL','OPT','CMAESMINRHO'),
                                 c('a','b','f','p'),F,'equal')
  get.many.CDR(file_list,'train')
})

rhoTracksRanks <- reactive({ subset(all.rhoTracksRanks(),
                                    Track %in% input$plotTracks & Rank %in% input$plotRanks) })

comparison <- reactive({
  if(!input$plotSDR) return(NULL)
  SDR=SDR()
  if(any(grepl('CMA-ES',rhoTracksRanks()$Track))){
    CMA <- get.CDR.CMA(input$problems, input$dimension, F, 'MinimumRho')
    CMA$SDR = 'CMA-ES'
    SDR <- rbind(SDR,CMA[,names(CMA) %in% names(SDR)])
  }
  return(SDR)
})

output$plot.rhoTracksRanks <- renderPlot({
  withProgress(message = 'Plotting boxplot', value = 0, {
    plot.rhoTracksRanks(rhoTracksRanks(), comparison())
  })
})

output$table.rhoTracksRanks <- renderTable({
  table.rhoTracksRanks(input$problem, subset(rhoTracksRanks()), comparison())
}, include.rownames = FALSE)
