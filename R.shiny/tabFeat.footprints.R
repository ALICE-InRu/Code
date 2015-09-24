output$tabFeat.footprints <- renderUI({
  dashboardBody(
    fluidRow(
      checkboxInput("sameQuartiles","Use same quartiles for all SDR (otherwise on corresponding Q1 and Q3)")
    ),
    fluidRow(
      box(title="Stepwise K-S test for difficulty", width = 9, collapsible = T,
          plotOutput("plot.kstest.SDR")),
      box(title='Settings', width=3, collapsible = T,
          checkboxInput("BonferroniKS","Only display Bonferroni adjustment"),
          sliderInput("KSWindowSDR","Sliding window for k",min=0,max=10,value=0),
          tableOutput("stat.kstest.SDR"))
      ),
    fluidRow(
      box(title="Stepwise correlation for difficulty w.r.t. SDR", width = 9, collapsible = T,
          plotOutput("plot.correlation.SDR")),
      box(title='Settings', width=3, collapsible = T,
          checkboxInput("BonferroniSDR","Only display Bonferroni adjustment",value=F),
          sliderInput("CorrWindowSDR","Sliding window for k",min=0,max=10,value=0),
          selectInput("DisplayDifficulty",'Display difficulties:',c('Both','Easy','Hard')),
          tableOutput("stat.correlation.SDR"))
      ),
    fluidRow(
      box(title="Stepwise correlation for difficulty over all trajectories", width = 9, collapsible = T,
          plotOutput("plot.correlation.all")),
      box(title='Settings', width=3, collapsible = T,
          checkboxInput("BonferroniALL","Bonferroni adjustment",value=T),
          sliderInput("CorrWindowALL","Sliding window for k",min=0,max=10,value=0),
          checkboxInput("PlotJointlyALL","Plot difficulties jointly",value=T),
          tableOutput("stat.correlation.all"))
      )
  )
})


footprint.dat <- reactive({
  withProgress(message = 'Retrieving data', value = 0, {
    dat=get.footprint.dat(input$problem,input$dimension,input$sameQuartiles,all.trdat())
    return(dat)
  })
})

corr.rho.SDR1 <- reactive({
  get.footprint.corr.rho(footprint.dat(),F,input$CorrWindowSDR)
})

corr.rho.SDR <- reactive({
  if(input$BonferroniSDR)
    subset(corr.rho.SDR1(),Bonferroni==T)
  else
    corr.rho.SDR1()
})

corr.rho.all1 <- reactive({
  corr.rho <- get.footprint.corr.rho(footprint.dat(),F,input$CorrWindowALL)
  corr.rho$Track='ALL'
  return(corr.rho)
})

corr.rho.all <- reactive({
  if(input$BonferroniALL)
    subset(corr.rho.all1(),Bonferroni==T)
  else
    corr.rho.all1()
})

ks.rho.SDR1 <- reactive({
  get.footprint.ks(footprint.dat(),F,input$KSWindowSDR)
})

ks.rho.SDR <- reactive({
  if(input$BonferroniKS)
    subset(ks.rho.SDR1(),Bonferroni==T)
  else
    ks.rho.SDR1()
})

output$plot.correlation.SDR <- renderPlot({
  withProgress(message = 'Correlation w.r.t. SDR', value = 0, {
    corr.rho = switch(input$DisplayDifficulty,
                      'Both'=corr.rho.SDR(),
                      'Easy'=subset(corr.rho.SDR(),Difficulty=='Easy'),
                      'Hard'=subset(corr.rho.SDR(),Difficulty=='Hard'))
    plot.correlation.matrix.stepwise(corr.rho)
  })
})

output$stat.correlation.SDR <- renderTable({
  xtable(stat.corr.Significant(corr.rho.SDR()))
}, include.rownames = FALSE)

output$plot.correlation.all <- renderPlot({
  withProgress(message = 'Testing correlation significance', value = 0, {
    p<-plot.correlation.matrix.stepwise(corr.rho.all())
    if(!input$PlotJointlyALL) {p<-p+facet_grid(Track~Difficulty)}
    return(p)
  })
})

output$stat.correlation.all <- renderTable({
  xtable(stat.corr.Significant(corr.rho.all()))
}, include.rownames = FALSE)

output$plot.kstest.SDR <- renderPlot({
  plot.ks.matrix.stepwise(ks.rho.SDR())
})

output$stat.kstest.SDR <- renderTable({
  xtable(stat.ks.Significant(ks.rho.SDR()))
}, include.rownames = FALSE)
