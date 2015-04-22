output$tabPref.imitationLearning <- renderUI({
  dashboardBody(
    fluidRow(
      # A static valueBox
      valueBox("Iterations", "Imitation learning", icon = icon("recycle"), width = 3),
      # Dynamic valueBoxes
      valueBoxOutput("progressBoxUnsup", width = 3),
      valueBoxOutput("progressBoxSup", width = 3),
      valueBoxOutput("progressBoxFixsup", width = 3)
    ),
    fluidRow(helpText('Using main problem distribution...')),
    fluidRow(
      box(width = 6, plotOutput("compareImitationLearning.boxplot")),
      box(width = 6, plotOutput("compareImitationLearning.weights")),
      box(width = 12, dataTableOutput("compareImitationLearning.stats"))
    )
  )
})

output$progressBoxSup <- renderValueBox({
  files = getSummaryFileNamesIL(input$problem,input$dimension,input$rank,input$probability,input$timedependent)
  valueBox( paste0('#',sum(grepl('[0-9]+SUP',files))), "Decreased supervision", color = "purple", icon = icon("eye"))
})
output$progressBoxUnsup <- renderValueBox({
  files = getSummaryFileNamesIL(input$problem,input$dimension,input$rank,input$probability,input$timedependent)
  valueBox( paste0('#',sum(grepl('[0-9]+UNSUP',files))), "Unsupervised", color = "yellow", icon = icon("eye-slash"))
})
output$progressBoxFixsup <- renderValueBox({
  files = getSummaryFileNamesIL(input$problem,input$dimension,input$rank,input$probability,input$timedependent)
  valueBox( paste0('#',sum(grepl('[0-9]+FIXSUP',files))), "Fixed supervision", color = "maroon", icon = icon("eyedropper"))
})

output$compareImitationLearning.boxplot <- renderPlot({
  compareImitationLearning.boxplot(input$problem,input$dimension,input$rank,input$probability,input$timedependent)
})
output$compareImitationLearning.weights <- renderPlot({
  compareImitationLearning.weights(input$problem,input$dimension,input$rank,input$probability,input$timedependent)
})
output$compareImitationLearning.stats <- renderDataTable({
  compareImitationLearning.stats(input$problem,input$dimension,input$rank,input$probability,input$timedependent)
},  options = list(paging = FALSE, searching = T))

getSummaryFileNamesIL <- function(problem,dim,rank,probability,timedependent){
  times=ifelse(timedependent,'timedependent','timeindependent')
  files=list.files('..//liblinear/CDR',paste('^summary.(full|exhaust)',problem,dim,rank,'*',probability,'weights',times,'csv',sep='.'))
  files=files[grep('OPT|IL',files)]
  return(files)
}

compareImitationLearning.boxplot <- function(problem,dim,rank,probability,timedependent){
  files = getSummaryFileNamesIL(problem,dim,rank,probability,timedependent)
  if(length(files)==0) return(NULL)
  CDR=NULL;
  for (file in files){
    file=substr(file,9,100)
    tmp=getSingleCDR(file,16,1,problem,dim,'train')
    CDR=rbind(CDR,tmp)
    tmp=getSingleCDR(file,16,1,problem,dim,'test')
    CDR=rbind(CDR,tmp)
  }

  CDR=formatData(CDR);
  p=liblinearBoxplot(CDR,NULL,'Supervision','Track','Imitation learning',F,ifelse(any(CDR$Extended),'Extended',NA))

  CDR$CDR=interaction(CDR$Track,CDR$Iter,substr(CDR$Supervision,1,1))
  #  ks.train=ks.matrix(subset(CDR,Set=='train'),'Rho','CDR')
  #  ks.test=ks.matrix(subset(CDR,Set=='test'),'Rho','CDR')

  return(p)
}

compareImitationLearning.weights <- function(problem,dim,rank,probability,timedependent){
  files = getSummaryFileNamesIL(problem,dim,rank,probability,timedependent)
  if(length(files)==0) return(NULL)
  w=NULL
  for (file in files){
    tmp=getWeights(substr(file,9,100),timedependent)
    tmp$Track=file
    w=rbind(w,tmp)
  }
  m=regexpr('(?<Track>[A-Z]{2}[A-Z0-9]+)',w$Track,perl=T);
  w$Track=getAttribute(w$Track,m,1)
  w=formatData(w)
  wopt=subset(w,Track=='OPT')

  if('Unsupervised' %in% levels(w$Supervision)){
    wopt$Supervision='Unsupervised'
    w=rbind(w,wopt)
  }
  if('Fixed' %in% levels(w$Supervision)){
    wopt$Supervision='Fixed'
    w=rbind(w,wopt)
  }
  w$Problem=problem

  w=ddply(w,~Iter+Supervision+Problem,mutate,sc.value=Step.1/sqrt(sum(Step.1*Step.1)))
  #print(ddply(w,~Iter+Supervision,'summarise',norm=sqrt(sum(sc.value^2)),min=min(sc.value),max=max(sc.value)))
  p=ggplot(w,aes(x=Iter,y=sc.value,color=Featurelbl,group=Feature))+geom_line()+geom_point()+
    facet_grid(Supervision~Problem)+
    ggplotCommon(NULL,'iteration',expression('Scaled weights for'*~phi))+
    scale_x_discrete(expand=c(0,-1))+
    guides(color = guide_legend(nrow = 4))+
    scale_color_discrete(expression('Feature'*~phi[i]*~''))

  return(p)
}

compareImitationLearning.stats <- function(problem,dim,rank,probability,timedependent){
  files = getSummaryFileNamesIL(problem,dim,rank,probability,timedependent)
  if(length(files)==0) return(NULL)
  stat=NULL;
  for (file in files){
    tmp=read.csv(paste('..//liblinear/CDR',file,sep='/'))
    tmp=subset(tmp,NrFeat==16 & Model==1)
    tmp$Track=file
    stat=rbind(stat,tmp)
  }

  m=regexpr('(?<Track>[A-Z]{2}[A-Z0-9]+)',stat$Track,perl=T);
  stat$Track=getAttribute(stat$Track,m,1)
  stat=formatData(stat)
  return(stat[order(stat$Iter,stat$Supervision),c(1,6:14)])
}
