output$tabGantt <- renderUI({
  dashboardBody(
    fluidRow(
      box(sliderInput("pid", "Problem instance:", min=1, max=500, value=10)),
      box(sliderInput("step", "Step:", min=0, max=30, value=30))
      ),
    fluidRow(helpText('Simple Priority Dispatching Rules')),
    fluidRow(
      box(title='Shortest Processing Time (SPT)', plotOutput('gantt.SPT',height = 200)),
      box(title='Largest Processing Time (LPT)', plotOutput('gantt.LPT',height = 200)),
      box(title='Least Work Remaining (LWR)', plotOutput('gantt.LWR',height = 200)),
      box(title='Most Work Remaining (MWR)', plotOutput('gantt.MWR',height = 200))
      ),
    fluidRow(helpText('Schedules from training data')),
    fluidRow(
      box(title='Random optimal trajectory', plotOutput('gantt.OPT',height = 200)),
      box(title='Random trajectory', plotOutput('gantt.RND',height = 200))
    )
  )
})

trdat.SPT <- reactive({ dispatchData(input$problem,'6x5','SPT',input$pid) })
trdat.LPT <- reactive({ dispatchData(input$problem,'6x5','LPT',input$pid) })
trdat.LWR <- reactive({ dispatchData(input$problem,'6x5','LWR',input$pid) })
trdat.MWR <- reactive({ dispatchData(input$problem,'6x5','MWR',input$pid) })
trdat.OPT <- reactive({ dispatchData(input$problem,'6x5','OPT',input$pid) })
trdat.RND <- reactive({ dispatchData(input$problem,'6x5','RND',input$pid) })

maxMakespan <- reactive({
  m=c(max(trdat.SPT()$phi.makespan), max(trdat.LPT()$phi.makespan),
      max(trdat.LWR()$phi.makespan), max(trdat.MWR()$phi.makespan),
      max(trdat.OPT()$phi.makespan), max(trdat.RND()$phi.makespan))
  return(max(m)+50)
})

output$gantt.SPT <- renderPlot({
  plotStep(trdat.SPT(),input$step,maxMakespan()) })
output$gantt.LPT <- renderPlot({
  plotStep(trdat.LPT(),input$step, maxMakespan()) })
output$gantt.LWR <- renderPlot({
  plotStep(trdat.LWR(),input$step, maxMakespan()) })
output$gantt.MWR <- renderPlot({
  plotStep(trdat.MWR(),input$step, maxMakespan()) })
output$gantt.OPT <- renderPlot({
  plotStep(trdat.OPT(),input$step, maxMakespan()) })
output$gantt.RND <- renderPlot({
  plotStep(trdat.RND(),input$step, maxMakespan()) })

dispatchData <- function(problem,dimension,SDR,plotPID=1){
  trdat <- getTrainingDataRaw(problem,dimension,'p',SDR,F)
  trdat <- subset(trdat,PID==plotPID)
  if(nrow(trdat)<1){return(NULL)}

  m=regexpr('(?<Job>[0-9]+).(?<Mac>[0-9]+).(?<StarTime>[0-9]+)',trdat$Dispatch,perl = T)
  trdat$Step=trdat$Step-min(trdat$Step)
  trdat$Job=as.numeric(getAttribute(trdat$Dispatch,m,1))+1
  trdat$Rho=round(trdat$Rho,2)
  trdat$phi.mac=trdat$phi.mac-min(trdat$phi.mac)+1

  return(trdat)
}

plotStep <- function(trdat,step,maxMakespan=0){

  NumJobs=max(trdat$Job)
  NumMacs=max(trdat$phi.mac)
  if(maxMakespan<max(trdat$phi.makespan))
    maxMakespan=max(trdat$phi.makespan)

  fdat <- subset(trdat,Followed==T & Step<step)
  pdat <- subset(trdat,Step==step)
  p=ggplot(fdat,aes(x=phi.startTime+(phi.endTime-phi.startTime)/2,
                    xmin=phi.startTime,
                    xmax=phi.endTime,
                    y=phi.mac,
                    ymin=phi.mac-0.4,
                    ymax=phi.mac+0.4,
                    fill=as.factor(Job),label=Job))+
    ggplotFill('Job',NumJobs)+xlab('')+
    scale_y_continuous('Machine', limits = c(0.6, NumMacs+1), breaks=1:NumMacs)+
    scale_x_continuous(expand=c(0,0), limits = c(0, maxMakespan))+
    theme(legend.position="none")

  if(nrow(fdat)>0){
    currentMakespan=max(fdat$phi.endTime)
    p=p+geom_rect()+geom_text(size=4)+
      geom_vline(xintercept=currentMakespan,linetype='dotted')+
      annotate("text", x = currentMakespan, y = NumMacs+0.6, size=4,
               label = "C[max]", parse=T, hjust=1, vjust=0)+
      annotate("text", x = currentMakespan, y = NumMacs+0.6, size=4,
               label = paste0('=',currentMakespan), hjust=0, vjust=0)
  }
  if(nrow(pdat)>0){
    p=p+geom_rect(data=pdat,
                  linetype='dashed', color='black',
                  alpha=0.2, #aes(size=Rho),
                  position = position_jitter(w = 0, h = 0.1))+
      #scale_size(guide="none",range=c(1.5,1))+ # stronger line for lower rho
      geom_text(data=pdat, size=4, position=position_jitter(w = 0.1, h = 0.1))
    #p=p+ggtitle(paste('Step',step))
  } #else { p = p + ggtitle('Complete schedule') }

  return(p)
}

createGif <- function(problem,dimension,SDR){

  trdat=dispatchData(problem,dimension,SDR)

  ## save images and convert them to a single GIF
  library(animation)
  saveGIF({
    for (step in unique(trdat$Step)) {
      print(plotStep(trdat,step))
    }
    print(plotStep(trdat,step+1))
}, interval = 0.5, movie.name = paste(problem,dimension,SDR,'gif',sep='.'), ani.width = 600, ani.height = 250, loop=F)

}
