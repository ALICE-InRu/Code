output$tabTable <- renderUI({
  dashboardBody(
    fluidRow(
      box(title="Settings", collapsible = T,
        selectInput("rawData", "Table:", c("OPT","SDR")),
        conditionalPanel("input.rawData == 'SDR'",
                         radioButtons("summary.var.sdr", "Statistics for", c("Rho","Makespan")),
                         selectInput("variable.sdr", "Summarise over variables:", c("Problem","Dimension","Set","SDR"),multiple=TRUE)),

        conditionalPanel("input.rawData == 'OPT'",
                         radioButtons("summary.var.opt", "Statistics for", c("Optimum")),
                         selectInput("variable.opt", "Summarise over variables:", c("Problem","Dimension","Set"),multiple=TRUE))
    )),
    fluidRow(dataTableOutput("stats.table"))
  )
})

output$stats.table <- renderDataTable({

  dat = switch(input$rawData,
               'SDR'=dataset.SDR(),
               'OPT'=subset(dataset.OPT,Problem %in% input$problems & Dimension %in% input$dimension))

  vars = switch(input$rawData,
                'SDR'=input$variable.sdr,
                'OPT'=input$variable.opt)

  if(is.null(vars)) { return(dat) }
  vars = vars[vars %in% colnames(dat)]
  over.var=switch(input$rawData,
                  'SDR'=input$summary.var.sdr,
                  'OPT'=input$summary.var.opt)

  if(!any(over.var %in% colnames(dat))) { return(dat) }

  stat=ddply(dat,.variables = vars, function(X) data.frame(as.list(summary(X[,over.var])), Cnt=nrow(X)))

}, options = list(pageLength = 5))
