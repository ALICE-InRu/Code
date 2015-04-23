output$tabSDR <- renderUI({
  dashboardBody(
    fluidRow(
      box(title="Settings", width=3,
          radioButtons("sdr.plot", "Plot type", c("Box plot"="boxplot","Density plot"="density"))),
      box(plotOutput("plot.SDR")) # Figure A.1
    )
  )
})

output$tabBDR <- renderUI({
  dashboardBody(
    fluidRow(
      box(title='Settings',
          selectInput("bdr.firstSDR", "First SDR", choices = c('SPT','LPT','MWR','LWR')),
          selectInput("bdr.secSDR", "Second SDR", choices = c('MWR','LWR','SPT','LPT')),
          sliderInput("bdr.split", "Cut off point:", min=0, max=100, value=40),
          helpText('Currently only applicable for 10x10',
                   'and the current default settings.')
      ),
      box(title='Plot', plotOutput("plot.BDR"))
    )
  )
})

output$tabDifficulty <- renderUI({
  dashboardBody(
    fluidRow(
      helpText('Use main problem distribution.'),
      box(title='Quartiles', tableOutput('diff.Quartiles'),
          helpText('Instances with rho lower than 1st.Qu. are catagorised as easy.',
                   'Likewise, instances with rho higher than 3rd.Qu. are catagorised as hard.')),
      box(title='Split', tableOutput('diff.Split')),
      box(title='Easy', tableOutput('diff.Easy')),
      box(title='Hard', tableOutput('diff.Hard'))
    )
  )
})

dataset.diff <- reactive({
  dat=subset(dataset.SDR(), Set=='train' & Dimension==input$dimension & Problem==input$problem)
  checkDifficulty(dat)
})
dataset.SDR <- reactive({
  subset(all.dataset.SDR,Problem %in% input$problems & Dimension == input$dimension)
})

output$diff.Quartiles <- renderTable({ xtable(dataset.diff()$Quartiles) }, include.rownames = FALSE)
output$diff.Split <- renderTable({ xtable(dataset.diff()$Split) }, include.rownames = FALSE)
output$diff.Easy <- renderTable({ xtable(splitSDR(dataset.diff()$Easy)) })
output$diff.Hard <- renderTable({ xtable(splitSDR(dataset.diff()$Hard)) })

output$plot.SDR <- renderPlot({

  dat=dataset.SDR()

  p=ggplot(dat,aes(fill=SDR,colour=Set))+
    ggplotColor("Data set",length(unique(dat$Set)))+
    ggplotFill("Simple priority dispatching rule",4,sdrNames)+
    ylab(rhoLabel)+
    facet_wrap(ncol=2,~Problem+Dimension,scales='free_y')+
    guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
           colour = guide_legend(order=2, direction = "vertical", title.position = "top")
    )

  p=p+switch(input$sdr.plot,
             'boxplot'=geom_boxplot(aes(x=SDR,y=Rho)),
             'density'=geom_density(aes(x=Rho),alpha=0.25))

  dir=paste(subdir,'boxplotRho',sep='/')
  fname=paste(paste(dir,'SDR',input$dimension,sep='.'),extension,sep='.')
  print(fname)
  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

}, height="auto")

output$plot.BDR <- renderPlot({

  dat=fetchBDR(input$dimension, input$problems, input$bdr.firstSDR, input$bdr.secSDR, input$bdr.split)
  if(is.null(dat)) return()
  BDR=paste(input$bdr.firstSDR,'(first',input$bdr.split,'%),',input$bdr.secSDR,'(last',100-input$bdr.split,'%)')
  p = ggplot(dat, aes(x=SDR,y=Rho,fill=SDR,color=Set))+geom_boxplot()+
    facet_wrap(~Problem+Dimension,ncol=2,scales='free_y')+
    ylab(rhoLabel)+
    guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
           colour = guide_legend(order=2, direction = "vertical", title.position = "top")
    )+
    ggplotColor('Data set',1)+
    ggplotFill('Dispatching rule',3,c(BDR,sdrNames[grep(unique(dat$SDR)[2],sdrs)],sdrNames[grep(unique(dat$SDR)[3],sdrs)]))

  fname=paste(subdir,'boxplotRho.BDR.10x10','.',extension,sep='')
  print(fname)
  if(input$save=='full')
    ggsave(filename=fname,plot=p, height=Height.full, width=Width, dpi=dpi, units=units)
  else if(input$save=='half')
    ggsave(filename=fname,plot=p, height=Height.half, width=Width, dpi=dpi, units=units)

  print(p)

}, height="auto")

checkDifficulty <- function(dat){

  quartiles=ddply(dat,~Problem+Dimension, summarise, Q1 = round(quantile(Rho,.25),digits = 2), Q3 = round(quantile(Rho,.75), digits = 2))
  rownames(quartiles)=interaction(quartiles$Problem,quartiles$Dimension)

  dat=merge(dat,quartiles)
  split = ddply(dat,~Problem+Dimension+SDR, summarise, Easy = round(mean(Rho<=Q1)*100,digits = 2), Hard = round(mean(Rho>Q3)*100,digits = 2))

  Easy = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho<=Q1]),N=length(PID))
  Hard = ddply(dat,~Problem+Dimension+SDR,summarise,PIDs=list(PID[Rho>=Q3]),N=length(PID))

  return(list('Quartiles'=quartiles,'Split'=split,'Easy'=Easy,'Hard'=Hard))
}

splitSDR <- function(dat,problem,dim){
  sdrs=unique(dat$SDR)
  N=length(sdrs)

  if(nrow(dat)==0){return(NULL)}
  m=matrix(nrow = N, ncol = N);
  colnames(m)=sdrs; rownames(m)=sdrs
  for(i in 1:N){
    iPID=subset(dat,SDR==sdrs[i])$PIDs[[1]]
    for(j in 1:N){
      jPID=subset(dat,SDR==sdrs[j])$PIDs[[1]]
      m[i,j]=round(length(intersect(jPID,iPID))/dat$N[i]*100,digits = 2)
    }
  }
  return(as.data.frame(m))
}

fetchBDR <- function(dim,problems,firstSDR,secSDR,split){
  fname=paste(paste(problems,collapse='|'),'*',firstSDR,secSDR,paste(split,'proc',sep=''),'csv',sep='.')
  BDR <- getfiles('../BDR/',pattern=fname)
  BDR$SDR='BDR'
  DAT = rbind(BDR,subset(all.dataset.SDR,SDR==firstSDR|SDR==secSDR))
  dat = subset(DAT,Dimension==dim & Problem %in% problems & Set=='train')
  if(nrow(subset(dat,SDR=='BDR'))==0) return(NULL)
  return(dat)
}
