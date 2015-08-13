output$tabPref.stepwiseBias <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Boxplot', width=12,
          plotOutput('plot.CDR.stepwiseBias', height=500)),
      box(title='Summary for Rho', width=9,
          tableOutput('table.CDR.stepwiseBias'))
    )
  )
})

CDR.stepwiseBias <- reactive({ get.CDR.stepwiseBias(input$problems,input$dimension) })

output$plot.CDR.stepwiseBias <- renderPlot({
  withProgress(message = 'Plotting boxplots', value = 0, {
    plot.CDR.stepwiseBias(CDR.stepwiseBias())
  })
})

output$table.CDR.stepwiseBias <- renderTable({
  table.CDR.stepwiseBias(CDR.stepwiseBias())
}, include.rownames=FALSE, sanitize.text.function=function(x){x})
