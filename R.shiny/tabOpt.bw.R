output$tabOpt.bw <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Following optimal trajectory',plotOutput('plot.stepwiseBestWorst.opt'),
          width = 12, collapsible = T)),
    fluidRow(helpText('Only main problem space considered.'),
      box(title='Following SDR trajectory',plotOutput('plot.stepwiseBestWorst.sdr'),collapsible = T,
          selectInput("bw.tracks", "Trajectories:",
                      c("OPT",sdrs,"ES.rho","ES.Cmax","ALL"), multiple = T, selected = 'ALL'),
          sliderInput('bw.k',"Guideline at step k:", min=0, max=100, value=0, step=1),
          sliderInput('bw.y',"Guideline at rho:", min=0, max=100, value=0, step=1)
          ),
      box(title='Compare following to not following policy', collapsible = T,
          selectInput("bw.variable", "Reference:", c("best.mu","worst.mu","mu"),selected = "mu"),
          checkboxInput("bw.order", "Display ordering"),
          tableOutput('table.stepwiseBestWorst.sdr'),
          helpText('Track boost is the mean improvement (if positive) for rho ',
                   'when using preference model compared to its original policy')
      )
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

output$table.stepwiseBestWorst.sdr <- renderTable({
  xtable(bw.spread(input$problem,input$dimension,input$bw.variable,input$bw.order))
}, include.rownames=F)
