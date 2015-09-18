output$tabOpt.bw <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Following optimal trajectory',plotOutput('plot.stepwiseBestWorst.opt')),
      box(title='Following SDR trajectory',plotOutput('plot.stepwiseBestWorst.sdr'),
          selectInput("bw.tracks", "Trajectories:",
                      c("OPT",sdrs,"ALL"), multiple = T, selected = 'ALL'),
          sliderInput('bw.k',"Guideline at step k:", min=0, max=100, value=0, step=1),
          sliderInput('bw.y',"Guideline at rho:", min=0, max=100, value=0, step=1),
          helpText('Only main problem space considered.'))
    )
  )
})
observe({
  input$bw.tracks
  dim=numericDimension(input$dimension)
  updateSliderInput(session, "bw.k", max=dim, value=isolate(input$bw.k))
})

output$plot.stepwiseBestWorst.opt <- renderPlot({
  withProgress(message = 'Plotting all problems', value = 0, {
    plot.BestWorst(input$problems,input$dimension,'OPT',input$save)
  })
})

BW <- reactive({
  withProgress(message = 'Loading best/worst case scenario', value = 0, {
    get.BestWorst(input$problem,input$dimension)
    })
})

output$plot.stepwiseBestWorst.sdr <- renderPlot({
  dim=numericDimension(input$dimension)
  k=input$bw.k
  p=plot.BestWorst(input$problem,input$dimension,input$bw.tracks,input$save,BW())
  if(k>0 & k<dim){
    p<-p+geom_vline(xintercept=k,color='red')
  }
  y=input$bw.y
  if(y>0){
    p<-p+geom_hline(yintercept=y,color='red')
  }
  return(p)
})
