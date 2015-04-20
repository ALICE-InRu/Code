output$tabTable <- renderUI({
  dashboardBody(
    fluidRow(
      box(
        selectInput("rawData", "Table:", c("OPT","SDR")),
        radioButtons("summary.var", "Statistics for", c("Rho","Makespan","Optimum")),
        selectInput("variable", "Summarise over variables:", c("Problem","Dimension","Set","SDR"),multiple=TRUE))
    ),
    fluidRow(dataTableOutput("stats.table"))
  )
})

output$stats.table <- renderDataTable({

  dat = switch(input$rawData,
               'SDR'=dataset.SDR(),
               'OPT'=subset(dataset.OPT,Problem %in% input$problems & Dimension %in% input$dimension))

  vars = input$variable
  if(is.null(vars)) { return(dat) }
  vars = vars[vars %in% colnames(dat)]
  over.var=input$summary.var
  if(!any(over.var %in% colnames(dat))) { return(dat) }

  stat=ddply(dat,.variables = vars, function(X) data.frame(as.list(summary(X[,over.var])), Cnt=nrow(X)))

}, options = list(pageLength = 5))
