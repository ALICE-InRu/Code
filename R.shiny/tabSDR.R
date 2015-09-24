output$tabSDR <- renderUI({
  dashboardBody(
    fluidRow(
      box(title="Settings", width=3,
          radioButtons("sdr.plot", "Plot type", c("Box plot"="boxplot","Density plot"="density"))),
      box(title="Plot", width=9, plotOutput("plot.SDR", height=600)) # Figure A.1
    )
  )
})

output$tabBDR <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Settings',
          selectInput("bdr.firstSDR", "First SDR", choices = c('SPT')),
          selectInput("bdr.secSDR", "Second SDR", choices = c('MWR')),
          sliderInput("bdr.split", "Cut off point:", min=0, max=100, value=40, step = 5),
          helpText('Currently only applicable for 10x10')
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

dat.Quartiles <- reactive({
  dat=subset(SDR(), Set=='train' & Problem==input$problem)
  get.quartiles(dat)
})

dataset.diff <- reactive({
  dat=subset(SDR(), Set=='train' & Problem==input$problem)
  checkDifficulty(dat,dat.Quartiles())
})

output$diff.Quartiles <- renderTable({ xtable(dataset.diff()$Quartiles) }, include.rownames = FALSE)
output$diff.Split <- renderTable({ xtable(dataset.diff()$Split) }, include.rownames = FALSE)
output$diff.Easy <- renderTable({ xtable(splitSDR(dataset.diff()$Easy)) })
output$diff.Hard <- renderTable({ xtable(splitSDR(dataset.diff()$Hard)) })

output$plot.SDR <- renderPlot({

  p = plot.SDR(SDR(),input$sdr.plot, input$save)
  print(p)

}, height="auto")

BDR <- reactive({
  withProgress(message = 'Loading BDR data', value = 0, {
    get.BDR('10x10','j.rnd',input$bdr.firstSDR,input$bdr.secSDR,seq(0,numericDimension('10x10'),by=5))
  })
})

output$plot.BDR <- renderPlot({

  p=plot.BDR('10x10','j.rnd',input$bdr.firstSDR,input$bdr.secSDR,input$bdr.split,BDR = BDR())
  print(p)

}, height="auto")

