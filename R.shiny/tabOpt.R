output$tabOpt <- renderUI({
  sidebarLayout(
    sidebarPanel(
      selectInput("optimality.plot", "Plot",
                  choices = c("Uniquness of optimal solutions"='stepwiseUniqueness',
                              "Optimality of solutions"='stepwiseOptimality',
                              "SDR optimality w.r.t. optimal"='stepwiseSDR.wrtOPT',
                              "SDR optimality w.r.t. trjactory"='stepwiseSDR.wrtTrack',
                              "Best/worst case scenario"='stepwiseBestWorst')),
      checkboxInput('smooth', 'Smooth'),
      checkboxInput('bwSDR', 'Check over SDRs'),
      helpText("Note: for best/worst case scenario",
               "only main problem space is considered.")
    ),
    mainPanel(
      fluidRow(plotOutput("plot.opt")) # Figure A.2-4 and A.8
    )
  )
})

dataset.Stepwise <- reactive({
  findStepwiseOptimality(input$problems,input$dimension)
})
dataset.Extremal <- reactive({
  findStepwiseExtremal(input$problems,input$dimension)
})

output$plot.opt <- renderPlot({

  dim=input$dimension
  if(length(dataset.Stepwise()$Stats)==0) return(NULL)

  withProgress(message = 'Making plot', value = 0, {
    if(input$optimality.plot=='stepwiseUniqueness'){
      p=plotStepwiseUniqueness(dataset.Stepwise(),input$smooth)
      fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','unique',extension,sep='.')
    } else if(input$optimality.plot=='stepwiseOptimality') {
      p=plotStepwiseOptimality(dataset.Stepwise(),F,input$smooth)
      fname=paste(paste(subdir,'stepwise',sep='/'),dim,'OPT',extension,sep='.')
    } else if(input$optimality.plot=='stepwiseBestWorst') {
      p=plotStepwiseBestWorst(dim,input$problems,!input$bwSDR)
      fname=ifelse(input$bwSDR,
                   paste(paste(subdir,input$problems[1],'stepwise',sep='/'),dim,'Track','casescenario',extension,sep='.'),
                   paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','casescenario',extension,sep='.'))
    } else if(input$optimality.plot=='stepwiseSDR.wrtTrack'){
      p=plotStepwiseSDR.wrtTrack(dataset.Stepwise(),dataset.Extremal(),input$problems,dim,input$smooth)
      fname=ifelse(length(input$problems)>1,
                   paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','SDR','TRACK',extension,sep='.'),
                   paste(paste(subdir,input$problems,'stepwise',sep='/'),dim,'OPT','SDR','TRACK',extension,sep='.'))
    } else if(input$optimality.plot=='stepwiseSDR.wrtOPT'){
      p=plotStepwiseSDR.wrtOPT(dataset.Stepwise(),dataset.Extremal(),input$smooth)
      fname=ifelse(length(input$problems)>1,
                   paste(paste(subdir,'stepwise',sep='/'),dim,'OPT','SDR',extension,sep='.'),
                   paste(paste(subdir,input$problems,'stepwise',sep='/'),dim,'OPT','SDR',extension,sep='.'))
    }
  })

  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

}, height="auto")

