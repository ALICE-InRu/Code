output$tabFeat.footprints <- renderUI({
  dashboardBody(
    fluidRow(
      box(width = 9, collapsible = T,
          plotOutput("plot.correlation.SDR"),
          checkboxInput("BonferroniSDR","Bonferroni adjustment",value=F),
          selectInput("DisplayDifficulty",'Display difficulties:',c('Both','Easy','Hard'))),
      box(width=3, collapsible = T,
          tableOutput("stat.correlation.SDR"))),
    fluidRow(
      box(width = 9, collapsible = T,
          plotOutput("plot.correlation.all"),
          checkboxInput("BonferroniAll","Bonferroni adjustment",value=T),
          checkboxInput("PlotJointlyAll","Plot difficulties jointly",value=T)),
      box(width=3, collapsible = T,
          tableOutput("stat.correlation.all"))),
    fluidRow(
      box(width = 12, dataTableOutput("stats.correlation"))
    )
  )
})


footprint.dat <- reactive({
  withProgress(message = 'Retrieving data', value = 0, {
    trdat <- get.files.TRDAT(input$problem, input$dimension, 'ALL', useDiff = F)
    trdat <- subset(trdat,Followed==T)

    trdat.lbl=labelDifficulty(subset(trdat,Step==max(trdat$Step)-1), # might be missing last step
                              quartiles())
    trdat.lbl$FinalRho = trdat.lbl$Rho
    trdat <- merge(trdat,trdat.lbl[,c('Problem','Track','PID','FinalRho','Difficulty')],
                   by=c('Problem','Track','PID'))
    trdat <- trdat[,grep('Track|PID|Step|phi|Difficulty|Rho',colnames(trdat))]
    trdat$Rho=NULL
  })
  return(trdat)
})

corr.rho.SDR <- reactive({
  corr.rho <- do.call(rbind, lapply(sdrs[1:4], function(sdr) {
    df <- correlation.matrix.stepwise(subset(footprint.dat(),Track==sdr),'FinalRho',input$BonferroniSDR)
    df$Track = sdr
    return(df) } ))
  return(corr.rho)
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
  mdat=ddply(corr.rho.SDR(),~Track+Difficulty+N,summarise,Significant=sum(Significant))
  mdat$Track <- factor(mdat$Track, levels=sdrs)
  mdat = arrange(mdat, Track, Difficulty)
  xtable(mdat)
}, include.rownames = FALSE)

corr.rho.all <- reactive({
  corr.rho <- correlation.matrix.stepwise(footprint.dat(),'FinalRho',input$BonferroniAll)
  corr.rho$Track='ALL'
  return(corr.rho)
})

output$plot.correlation.all <- renderPlot({
  withProgress(message = 'Testing correlation significance', value = 0, {
    p<-plot.correlation.matrix.stepwise(corr.rho.all())
    if(!input$PlotJointlyAll) {p<-p+facet_grid(Track~Difficulty)}
    return(p)
  })
})

output$stat.correlation.all <- renderTable({
  mdat=ddply(corr.rho.all(),~Track+Difficulty+N,summarise,Significant=sum(Significant))
  xtable(mdat)
}, include.rownames = FALSE)


output$stats.correlation <- renderTable({

})
