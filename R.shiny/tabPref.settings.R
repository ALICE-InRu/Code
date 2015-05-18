output$tabPref.settings <- renderUI({
  dashboardBody(
    fluidRow(
      # Dynamic valueBoxes
      valueBoxOutput("progressPrefs", width = 3),
      valueBoxOutput("progressTracks", width = 3),
      valueBoxOutput("progressRanks", width = 3),
      valueBoxOutput("progressBias", width = 3)
    ),
    fluidRow(helpText('Using main problem distribution...')),
    fluidRow(
      box(title = "Settings", status = "primary", solidHeader = TRUE,
          selectInput("tracks", "Trajectories:", c("OPT",sdrs,"RND","ALL","ILSUP","ILUNSUP","ILFIXSUP", "OPTEXT","ILUNSUPEXT","LOCOPT","CMAESMINRHO"), multiple = T, selected = 'OPT'),
          selectInput("rank", "Ranking:", c("p","f","b","a")),
          selectInput("bias", "Stepwise bias:", c('equal','opt','wcs','bcs','dbl1st','dbl2nd')),
          checkboxInput("exhaustive","Exhaustive search for models, i.e., 1,2,3 or all $d$ features"),
          checkboxInput("timedependent","Stepwise dependent:"),
          actionButton("create", "Create:")
      ),
      box(title = "Stepwise bias",
          helpText('Features instances are resampled w.r.t. its stepwise bias.'),
          plotOutput("plot.stepwiseBias", height = 150)),
      box(title = "LiblineaR Output", width = 6,
          verbatimTextOutput("output.liblinearModel"))
    )
  )
})

dataset.training <- reactive({
  getTrainingDataRaw(input$problem,input$dimension,input$tracks)
})

output$plot.stepwiseBias <- renderPlot({
  steps=1:numericDimension(input$dimension)
  w=get.stepwiseBias(steps,input$problem,input$dimension,input$bias)
  df=data.frame('Step'=steps,'Weight'=w)
  ggplot(df,aes(x=Step,y=Weight))+geom_line()+scale_x_continuous(expand=c(0,0))
})

output$output.liblinearModel <- renderPrint({
  input$create
  print(Sys.time())

  tracks=isolate(input$tracks)
  problem=isolate(input$problem)
  dimension=isolate(input$dimension)
  rank=isolate(input$rank)
  exhaustive=isolate(input$exhaustive)
  bias=isolate(input$bias)
  timedependent=isolate(input$timedependent)

  patTracks=tracks
  ix=grep('IL',patTracks)
  if(any(ix)){
    patTracks[ix]=paste0('IL[0-9]+',stringr::str_sub(patTracks[ix],3))
  }
  patTracks=paste0('(',paste(patTracks,collapse='|'),')')
  fT=list.files(paste0(DataDir,'Training'),paste('^trdat',problem,dimension,patTracks,'Local','diff',rank,'csv',sep='.'))
  fW=list.files(paste0(DataDir,'PREF/weights'),paste(ifelse(exhaustive,'exhaust','full'),problem,dimension,rank,tracks,bias,'weights',ifelse(timedependent,'timedependent','timeindependent'),'csv',sep='.'))
  if(length(fT)+any(grepl('ALL',tracks))>length(fW)){

    lmax=ifelse(numericDimension(input$dimension)<100,
                ifelse(timedependent,5000,100000),
                ifelse(timedependent,100000,500000))

    for(track in tracks)
      withProgress(message = paste('Create model for',track), value = 0, {
        create.prefModel(problem,dimension,track,rank,bias,timedependent,exhaustive,lmax)
      })
  } else { return(paste(length(fW),'LIBLINEAR models exist for current setting')) }
})

pref.files <- reactive({
  list.files(paste0(DataDir,'PREF/weights'),paste(input$problem,input$dimension,'[a-z]{1}','[A-Z0-9]+','[a-z]+','weights','time[dependent|independent]*','csv',sep='.'))
})

pref.files.pat = paste('(?<Rank>[a-z]{1})','(?<Track>[A-Z0-9]+)','(?<Bias>[a-z]+)','weights','time[dependent|independent]*','csv',sep='.')

output$progressPrefs <- renderValueBox({
  valueBox( paste0('#',length(pref.files())), "models", color = "navy", icon = icon("users"))
})

output$progressTracks <- renderValueBox({
  m=regexpr(pref.files.pat,pref.files(),perl = T)
  track=unique(getAttribute(pref.files(),m,'Track'))
  ntrack=sum(grepl('^[A-Z]{3}',track))+
    any(grepl('[0-9]+UNSUP',track))+
    any(grepl('[0-9]+SUP',track))+
    any(grepl('[0-9]+FIXSUP',track))
  valueBox( paste0('#',ntrack), "trajectories", color = "teal", icon = icon("user"))
})

output$progressRanks <- renderValueBox({
  m=regexpr(pref.files.pat,pref.files(),perl = T)
  rank=unique(getAttribute(pref.files(),m,'Rank'))
  valueBox( paste0('#',length(rank)), "ranks", color = "olive", icon = icon("filter"))
})

output$progressBias <- renderValueBox({
  m=regexpr(pref.files.pat,pref.files(),perl = T)
  bias=unique(getAttribute(pref.files(),m,'Bias'))
  valueBox( paste0('#',length(bias)), "bias", color = "lime", icon = icon("eraser"))
})
