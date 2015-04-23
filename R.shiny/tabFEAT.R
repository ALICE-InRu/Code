output$tabFEAT <- renderUI({
  dashboardBody(
    fluidRow(
      #box(title="Extremal", plotOutput("plot.extremal", height=700)),
      box(title="Local", plotOutput("plot.local", height=350)),
      #box(title="Global", plotOutput("plot.global", height=350))
    )
  )
})

output$plot.extremal <- renderPlot({
  problem=input$problem
  dim=input$dimension
  Stepwise=dataset.Stepwise()
  Extremal=dataset.Extremal()
  if(length(Stepwise$Stats)==0) return(NULL)
  withProgress(message = 'Making plot', value = 0, {
    p=plotStepwiseExtremal(Stepwise,Extremal,F)
  })
  print(problem)
  print(dim)
  fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'OPT','extremal',extension,sep='.')
  print(fname)
  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)
},height="auto")

output$plot.global <- renderPlot({
  problem=input$problem
  dim=input$dimension
  withProgress(message = 'Making plot', value = 0, {
    p=plotStepwiseFeatures(problem,dim,T)
  })
  fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'Track','evolution','Global',extension,sep='.')
  print(fname)
  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)
},height="auto")

output$plot.local <- renderPlot({
  problem=input$problem
  dim=input$dimension
  withProgress(message = 'Making plot', value = 0, {
    p=plotStepwiseFeatures(problem,dim,F)
  })
  fname=paste(paste(subdir,problem,'stepwise',sep='/'),dim,'Track','evolution','Local',extension,sep='.')
  print(fname)
  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)
  print(p)
},height="auto")
