output$tabSDR <- renderUI({
  dashboardBody(
    fluidRow(
      box(title="Settings", width=3,
          radioButtons("sdr.plot", "Plot type", c("Box plot"="boxplot","Density plot"="density"))),
      box(title="Plot", width=9, plotOutput("plot.SDR")) # Figure A.1
    )
  )
})

output$tabBDR <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Settings',
          selectInput("bdr.firstSDR", "First SDR", choices = c('SPT','LPT','MWR','LWR')),
          selectInput("bdr.secSDR", "Second SDR", choices = c('MWR','LWR','SPT','LPT')),
          sliderInput("bdr.split", "Cut off point:", min=0, max=100, value=40),
          helpText('Currently only applicable for 10x10',
                   'and the current default settings.')
      ),
      box(title='Plot', plotOutput("plot.BDR"))
    )
  )
})

output$tabDifficulty <- renderUI({
  dashboardBody(
    fluidRow(
      helpText('Use main problem distribution.'),
      box(title='Quartiles', tableOutput('diff.Quartiles'),
          helpText('Instances with rho lower than 1st.Qu. are catagorised as easy.',
                   'Likewise, instances with rho higher than 3rd.Qu. are catagorised as hard.')),
      box(title='Split', tableOutput('diff.Split')),
      box(title='Easy', tableOutput('diff.Easy')),
      box(title='Hard', tableOutput('diff.Hard'))
    )
  )
})

SDR <- reactive({
  subset(dataset.SDR,Problem %in% input$problems & Dimension == input$dimension)
})

dataset.diff <- reactive({
  dat=subset(SDR(), Set=='train' & Dimension==input$dimension & Problem==input$problem)
  checkDifficulty(dat)
})

output$diff.Quartiles <- renderTable({ xtable(dataset.diff()$Quartiles) }, include.rownames = FALSE)
output$diff.Split <- renderTable({ xtable(dataset.diff()$Split) }, include.rownames = FALSE)
output$diff.Easy <- renderTable({ xtable(splitSDR(dataset.diff()$Easy)) })
output$diff.Hard <- renderTable({ xtable(splitSDR(dataset.diff()$Hard)) })

output$plot.SDR <- renderPlot({

  p = plot.SDR(SDR(),input$sdr.plot, input$save)
  print(p)

}, height="auto")

output$plot.BDR <- renderPlot({

  p=plot.BDR(input$dimension,input$problems,input$bdr.firstSDR,input$bdr.secSDR,input$bdr.split,input$save)
  print(p)

}, height="auto")

