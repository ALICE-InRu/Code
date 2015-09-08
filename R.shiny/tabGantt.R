output$tabGantt <- renderUI({
  dashboardBody(
    fluidRow(helpText('Gantt charts that illustrate the (temporal partial) job-shop',
                      'schedule for a given DR. Numbers in the boxes represent the',
                      'job identification j. The width of the box illustrates the','
                      processing times for a given job for a particular machine a',
                      '(on the vertical axis). The dashed boxes represent the resulting',
                      'partial schedule for when a particular job is scheduled next.',
                      'Moreover, the current Cmax is denoted with a dotted line.')),
    fluidRow(
      box(sliderInput("pid", "Problem instance:", min=1, max=500, value=10)),
      box(sliderInput("step", "Step during the dispatching process:", min=0, max=30, step=1, value=30))
      ),
    fluidRow(
      box(width=12, plotOutput('gantt.schedules', height = 700)),
      box(checkboxInput("plotPhi", "Display features."))
      )
  )
})

observe({
  dim=numericDimension(input$dimension)
  updateSliderInput(session, "step", max=dim, value=dim)
})

all.trdat <- reactive({
  get.files.TRDAT(input$problem, input$dimension, 'ALL', useDiff = F)
})

all.dat.schedules <- reactive({
  withProgress(message = 'Loading schedules', value = 0, {
    get.gantt(input$problem,input$dimension,'ALL',all.trdat=all.trdat())
  })
})

dat.schedules <- reactive({ subset(all.dat.schedules(),PID==input$pid) })

output$gantt.schedules <- renderPlot({ plot.gantt(dat.schedules(),input$step,plotPhi = input$plotPhi) })

