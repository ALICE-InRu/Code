output$tabPref.settings <- renderUI({
  dashboardBody(
    fluidRow(
      # Dynamic valueBoxes
      valueBoxOutput("progressPrefs", width = 3),
      valueBoxOutput("progressTracks", width = 3),
      valueBoxOutput("progressRanks", width = 3),
      valueBoxOutput("progressProbs", width = 3)
    ),
    fluidRow(helpText('Using main problem distribution...')),
    fluidRow(
      box(title = "Settings", status = "primary", solidHeader = TRUE, collapsible = TRUE,
        selectInput("tracks", "Trajectories:", c("OPT",sdrs,"RND","ALL","ILSUP","ILUNSUP","ILFIXSUP", "OPTEXT","ILUNSUPEXT"), multiple = T, selected = 'OPT'),
        selectInput("rank", "Ranking:", c("p","f","b","a")),
        selectInput("probability", "Stepwise bias:", c('equal','opt','wcs','bcs','dbl1st','dbl2nd')),
        checkboxInput("exhaustive","Exhaustive search for models, i.e., 1,2,3 or all $d$ features"),
        checkboxInput("timedependent","Stepwise dependent:"),
        selectInput("liblinearModel", "Action:", c("Estimate", "Create")),
        actionButton("action", "Submit:")
      ),
      box(title = "Stepwise bias", collapsible = TRUE,
          helpText('Features instances are resampled w.r.t. its stepwise bias.'),
          plotOutput("plot.probability", height = 150)),
      box(title = "Action output", width = 6, collapsible = TRUE,
          verbatimTextOutput("output.liblinearModel"))
    ),
    fluidRow(
      box(plotOutput('plot.trainingDataSize')),
      box(plotOutput('plot.preferenceSetSize'))
    )
  )
})

dataset.training <- reactive({
  getTrainingDataRaw(input$problem,input$dimension,input$tracks)
})

output$plot.probability <- renderPlot({
  steps=1:Dimension()
  w=stepwiseProbability(steps,input$problem,input$dimension,input$probability)
  df=data.frame('step'=steps,'Weight'=w)
  ggplot(df,aes(x=step,y=Weight))+geom_line()
})

output$output.liblinearModel <- renderPrint({
  input$action
  print(Sys.time())

  tracks=isolate(input$tracks)
  problem=isolate(input$problem)
  dimension=isolate(input$dimension)
  rank=isolate(input$rank)
  exhaustive=isolate(input$exhaustive)
  probability=isolate(input$probability)
  timedependent=isolate(input$timedependent)

  if(isolate(input$liblinearModel)=="Estimate") {
    estimateLiblinearModels(problem,dimension,ifelse(exhaustive,'exhaust','full'),probability,timedependent,tracks,rank)
  } else {
    patTracks=tracks
    patTracks[grepl('ILSUP',patTracks)]='IL[0-9]+SUP'
    patTracks[grepl('ILUNSUP',patTracks)]='IL[0-9]+UNSUP'
    patTracks[grepl('ILFIXSUP',patTracks)]='IL[0-9]+FIXSUP'
    patTracks=paste0('(',paste(patTracks,collapse='|'),')')
    fT=list.files('../trainingData/',paste('^trdat',problem,dimension,patTracks,'Local','diff',rank,'csv',sep='.'))
    fW=list.files(paste('..//liblinear',dimension,sep='/'),paste(ifelse(exhaustive,'exhaust','full'),problem,dimension,rank,tracks,probability,'weights',ifelse(timedependent,'timedependent','timeindependent'),'csv',sep='.'))
    if(length(fT)+any(grepl('ALL',tracks))>length(fW)){
      lmax=ifelse(Dimension()<100,ifelse(timedependent,5000,100000),ifelse(timedependent,100000,500000))
      for(track in tracks)
        withProgress(message = paste('Create LIBLINEAR model for',track), value = 0, {
          createLiblinearModel(problem,dimension,track,rank,probability,timedependent,exhaustive,lmax)
        })
    } else { return(paste(length(fW),'LIBLINEAR models exist for current setting')) }
  }
})

pref.files <- reactive({
  list.files(paste('../liblinear',input$dimension,sep='/'),paste(input$problem,input$dimension,'[a-z]{1}','[A-Z0-9]+','[a-z]+','weights','time[dependent|independent]*','csv',sep='.'))
})
pref.files.pat = paste('(?<rank>[a-z]{1})','(?<track>[A-Z0-9]+)','(?<prob>[a-z]+)','weights','time[dependent|independent]*','csv',sep='.')

output$progressPrefs <- renderValueBox({
  valueBox( paste0('#',length(pref.files())), "models", color = "navy", icon = icon("users"))
})

output$progressTracks <- renderValueBox({
  m=regexpr(pref.files.pat,pref.files(),perl = T)
  track=unique(getAttribute(pref.files(),m,2))
  ntrack=sum(grepl('^[A-Z]{3}',track))+
    any(grepl('[0-9]+UNSUP',track))+
    any(grepl('[0-9]+SUP',track))+
    any(grepl('[0-9]+FIXSUP',track))
  valueBox( paste0('#',ntrack), "trajectories", color = "teal", icon = icon("user"))
})

output$progressRanks <- renderValueBox({
  m=regexpr(pref.files.pat,pref.files(),perl = T)
  rank=unique(getAttribute(pref.files(),m,1))
  valueBox( paste0('#',length(rank)), "ranks", color = "olive", icon = icon("filter"))
})

output$progressProbs <- renderValueBox({
  m=regexpr(pref.files.pat,pref.files(),perl = T)
  probs=unique(getAttribute(pref.files(),m,3))
  valueBox( paste0('#',length(probs)), "probabilities", color = "lime", icon = icon("eraser "))
})

output$plot.trainingDataSize <- renderPlot({
  input$action
  if(isolate(input$liblinearModel)=="Estimate") {
    dim=isolate(input$dimension)
    p=plot.trainingDataSize(isolate(input$problem),dim,isolate(input$tracks))
    fname=paste(paste(subdir,'trdat',sep='/'),'size',dim,extension,sep='.')
    #ggsave(fname,p,width=Width,height=Height.half,dpi=dpi,units=units)
    return(p)
  }
})

output$plot.preferenceSetSize <- renderPlot({
  input$action
  if(isolate(input$liblinearModel)=="Estimate") {
    dim=isolate(input$dimension)
    p=plot.preferenceSetSize(isolate(input$problem),dim,
                             isolate(input$tracks),isolate(input$rank))

    fname=paste(paste(subdir,'prefdat',sep='/'),'size',dim,extension,sep='.')
    #ggsave(fname,p,width=Width,height=Height.full,dpi=dpi,units=units)
    return(p)
  }
})




