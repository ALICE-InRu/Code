output$tabOpt <- renderUI({
  dashboardBody(
    fluidRow(box(title='Settings',collapsible = T, checkboxInput('smooth', 'Smooth'))),
    fluidRow(
      box(title='Uniqueness of optimal solutions',plotOutput('plot.stepwiseUniqueness')),
      box(title='Optimality of solutions',plotOutput('plot.stepwiseOptimality')),
      box(title='SDR optimality w.r.t. optimal',plotOutput('plot.stepwiseSDR.wrtOPT')),
      box(title='SDR optimality w.r.t. trajectory',plotOutput('plot.stepwiseSDR.wrtTrack'))
    )
  )
})

output$tabBestWorstCase <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Following optimal trajectory',plotOutput('plot.stepwiseBestWorst.opt')),
      box(title='Following SDR trajectory',plotOutput('plot.stepwiseBestWorst.sdr'),
          helpText('Only main problem space considered.'))
    )
  )
})

dataset.Stepwise <- reactive({
  withProgress(message = 'Loading stepwise data', value = 0, {
    findStepwiseOptimality(input$problems,input$dimension)
  })
})
dataset.Extremal <- reactive({
  withProgress(message = 'Loading extremal data', value = 0, {
    findStepwiseExtremal(input$problems,input$dimension)
  })
})

output$plot.stepwiseUniqueness <- renderPlot({

  dim=input$dimension
  if(length(dataset.Stepwise()$Stats)==0) return(NULL)

  withProgress(message = 'Making plotStepwiseUniqueness', value = 0, {
    p=plotStepwiseUniqueness(dataset.Stepwise(),input$smooth)
  })

  fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','unique',extension,sep='.')
  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

}, height="auto")

output$plot.stepwiseOptimality <- renderPlot({

  dim=input$dimension
  if(length(dataset.Stepwise()$Stats)==0) return(NULL)

  withProgress(message = 'Making plotStepwiseOptimality', value = 0, {
    p=plotStepwiseOptimality(dataset.Stepwise(),F,input$smooth)
  })
  fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT',extension,sep='.')

  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

}, height="auto")

output$plot.stepwiseBestWorst.opt <- renderPlot({

  dim=input$dimension

  withProgress(message = 'Making plotStepwiseBestWorst', value = 0, {
    p=plotStepwiseBestWorst(input$problems,input$dimension,'OPT')
  })
  fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','casescenario',extension,sep='.')

  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

})

output$plot.stepwiseBestWorst.sdr <- renderPlot({

  dim=input$dimension

  withProgress(message = 'Making plotStepwiseBestWorst', value = 0, {
    p=plotStepwiseBestWorst(input$problem,input$dimension,'ALL')
  })
  fname=paste(paste(subdir,input$problem,'stepwise',sep='/'),dim,'Track','casescenario',extension,sep='.')

  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

})

output$plot.stepwiseSDR.wrtTrack <- renderPlot({

  dim=input$dimension
  if(length(dataset.Stepwise()$Stats)==0) return(NULL)

  withProgress(message = 'Making plotStepwiseSDR.wrtTrack', value = 0, {
    p=plotStepwiseSDR.wrtTrack(dataset.Stepwise(),dataset.Extremal(),input$problems,dim,input$smooth)
  })
  fname=ifelse(length(input$problems)>1,
               paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','SDR','TRACK',extension,sep='.'),
               paste(paste(subdir,input$problems,'stepwise',sep='/'),dim,'OPT','SDR','TRACK',extension,sep='.'))

  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

}, height="auto")

output$plot.stepwiseSDR.wrtOPT <- renderPlot({

  dim=input$dimension
  if(length(dataset.Stepwise()$Stats)==0) return(NULL)

  withProgress(message = 'Making plotStepwiseSDR.wrtOPT', value = 0, {
    p=plotStepwiseSDR.wrtOPT(dataset.Stepwise(),dataset.Extremal(),input$smooth)
  })

  fname=ifelse(length(input$problems)>1,
               paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','SDR',extension,sep='.'),
               paste(paste(subdir,input$problems,'stepwise',sep='/'),dim,'OPT','SDR',extension,sep='.'))

  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

}, height="auto")
