output$tabPref.exhaustive <- renderUI({
  dashboardBody(
    fluidRow(helpText('Using main problem distribution and preferably 10x10 dimension. Check settings to set trajectory used.')),
    fluidRow(
      box(title = "Pareto front", collapsible = TRUE, width=12,
          #tags$head( tags$script(src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML-full", type = 'text/javascript'),tags$script( "MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});", type='text/x-mathjax-config')),
          helpText('Scatter plot for validation accuracy (%) against its corresponding mean expected $\\rho$ (%) for all', choose(16,16)+choose(16,1)+choose(16,2)+choose(16,3), 'linear models, based on either one, two, three or all $d$ combinations of features. Pareto fronts for each active feature count based on maximum validation accuracy and minimum mean expected $\\rho$ (%), and labelled with their model ID. Moreover, actual Pareto front over all models is marked with triangles.'),
          plotOutput("plot.pareto.front", height = 250)),
      box(title = "Training accuracy", collapsible = TRUE, width=12,
          helpText('Various methods of reporting validation accuracy for preference learning'),
          plotOutput("plot.training.acc", height = 250)),
      box(title = "Stepwise optimality of dispatches", collapsible = TRUE, width=12,
          helpText('Probability of choosing optimal move for models corresponding to highest mean validation accuracy (grey) and lowest mean deviation from optimality, $\\rho$, (black) compared to the baseline of probability of choosing an optimal move at random (dashed)'),
          plotOutput("plot.exhaust.best", height = 250)),
      #,plotOutput("plot.exhaust.best.diff", height = 250)),
      box(title = "Normalised weights", collapsible = TRUE, width=12,
          helpText('Normalised weights for CDR models, models are grouped w.r.t. its dimensionality, $d$. Note, a triangle indicates a solution on the Pareto front.'),
          plotOutput("plot.pareto.phi", height = 250)),
      box(title='Pareto front', collapsible=TRUE, width=12,
          tableOutput("table.paretoFront")),
      box('Kolmogorov-Smirnov Tests for main distribution', collapsible = TRUE, width=12,height=1000,
          helpText('p-values for two-sided Kolmogorov-Smirnov test.'),
          box(title='w.r.t. $\\rho$ for training set', width=6,
              tableOutput("table.liblinearKolmogorov.Rho.train")),
          box(title='w.r.t. $\\rho$ for test set', width=6,
              tableOutput("table.liblinearKolmogorov.Rho.test")),
          box(title='w.r.t. training accuracy', width=6,
              tableOutput("table.liblinearKolmogorov.Acc")))
    )
  )
})

Probability <- reactive({
  probabilities=input$probability
  prob=ifelse(length(probabilities)>1,'all',probabilities)
  return(prob)
})

Problem <- reactive({
  problems=input$problems
  problems=ifelse(length(problems)>1,'all',problems)
  return(problems)
})


Liblinear.Summary <- reactive({
  tracks=input$tracks
  if(is.null(tracks)){ return(NULL) }
  probabilities=input$probability
  problems=input$problems
  timedependent=input$timedependent
  dim=input$dimension
  rank=input$rank

  ix=grepl('IL',tracks)
  if(any(ix)){ tracks[ix]=paste0(substr(tracks[ix],1,2),'[0-9]+',substr(tracks[ix],3,100)) }
  pat=paste('^summary','exhaust',
            paste0('(',paste(problems,collapse = '|'),')'),dim,rank,
            paste0('(',paste(tracks,collapse = '|'),')'),
            paste0('(',paste(probabilities,collapse='|'),')'),'weights',
            ifelse(timedependent,'timedependent','timeindependent'),'csv$',sep='.')
  models=list.files('..//liblinear/CDR',pat)
  pref=NULL
  for(model in models){ pref=rbind(pref,getPrefInfo(substr(model,9,100))); }
if(is.null(pref)){return(NULL)}
  return(pref)
})

Pareto.front <- reactive({

  pref=Liblinear.Summary()
  if(is.null(pref)) return(NULL)

  dat.fronts=NULL
  for(problem in levels(pref$Problem)){
    pfront=pareto.ranking.wrtNrFeat(subset(pref,Problem==problem))
    dat.fronts=rbind(dat.fronts,pfront)
  }
  return(dat.fronts)

})

output$plot.pareto.front <- renderPlot({

  plotParetoFront <- function(dat,front,plotAllSolutions){
    p=ggplot(dat,aes(x=Validation.Accuracy.Optimality, y=Validation.Rho,color=NrFeat))+
      facet_grid(~Problem,scales='free_y')

    if(length(unique(front$Prob))>1){
      if(plotAllSolutions){p=p+geom_point(aes(shape=Prob))}
      p=p+geom_point(data=front,aes(shape=Prob,size=Pareto.front))
    } else {
      if(plotAllSolutions){p=p+geom_point()}
      p=p+geom_point(data=front,aes(shape=Pareto.front),size=5)
    }

    p=p+geom_line(data=front,size=1)+
      guides(size=FALSE)+ggplotColor('Feature count',length(unique(dat$NrFeat)))+
      geom_text(data=front,aes(label=Model),color='black',size=3)+
      xlab('Mean stepwise optimality accuracy (%)')+
      ylab(expression('Expected mean for'*~rho*~'(%)'))+
      themeVerticalLegend+guides(
        colour = guide_legend(ncol = 2, byrow = T),
        shape = guide_legend(ncol = 1, byrow = T)
      )
    return(p)
  }

  pref=Liblinear.Summary()
  dat.fronts=Pareto.front()
  if(is.null(pref)|is.null(dat.fronts)) return(NULL)

  plotAllSolutions=T
  p=plotParetoFront(pref,dat.fronts,plotAllSolutions)

  if(input$save!='NA'){
    fname=paste(subdir,paste('pareto',Probability(),Problem(),extension,sep='.'),sep='/')
    ggsave(fname,p,units=units,width=Width,height=Height.half)
  }

  return(p)

})

output$plot.training.acc <- renderPlot({

  pref=Liblinear.Summary()
  if(is.null(pref)) return(NULL)

  p=ggplot(pref,aes(x=Validation.Rho))+facet_grid(~Problem, scales='free')+
    geom_point(aes(y=Validation.Accuracy.Classification,color='classification',shape=Prob))+
    geom_point(aes(y=Validation.Accuracy.Optimality,color='optimality',shape=Prob))+
    ggplotColor(name = "Mean stepwise", num=2)+
    xlab(expression('Expected mean for'*~rho*~'(%)'))+
    ylab('Validation accuracy (%)')+
    themeVerticalLegend

  if(Probability()!='all'){p=p+scale_shape_discrete(guide = F)}

  if(input$save!='NA'){
    fname=paste(subdir,paste('training','accuracy',Probability(),Problem(),extension,sep='.'),sep='/')
    ggsave(fname,p,units=units,width=Width,height=Height.half)
  }
  return(p)
})

output$plot.pareto.phi <- renderPlot({

  plotLinearWeights <- function(front,timedependent){

    weights=NULL
    for(file in unique(front$File)){
      tmp=getWeights(file,timedependent);tmp$Type=NULL;tmp$File=file
      weights=rbind(weights,tmp)
    }
    mdat=join(weights,front,by=c('NrFeat','Model','File'))
    mdat=subset(mdat,CDR %in% front$CDR)

    colnames(mdat)[grep('Step.1',colnames(mdat))]='value'

    ## Rescale each weight to be normalised to 1
    mdat=ddply(mdat,~Problem+NrFeat+CDRlbl,mutate,sc.value=value/sqrt(sum(value*value)))
    mdat$Featurelbl = factor(mdat$Featurelbl,levels=rev(levels(mdat$Featurelbl)))

    library('scales') # for muted
    p=ggplot(mdat, aes(fill=sc.value,x=CDRlbl,y=Featurelbl))+
      geom_tile(color='black')+
      geom_point(data=subset(mdat,Pareto.front==T),aes(label='pareto'),shape=17)+
      scale_fill_gradient2(name='Normalised\nweights', low = muted("red"), mid = "white",
                           high = muted("blue"), midpoint = 0, space = "rgb",
                           na.value = "grey50", guide = "colourbar")+
      facet_grid(Problem~NrFeat,scales='free_x',space='free_x')+
      ylab(expression('Feature'*~phi))+xlab('')+
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
            legend.position = 'right', legend.direction='vertical')

    return(p)
  }

  pref=Liblinear.Summary()
  dat.fronts=Pareto.front()
  if(is.null(pref)|is.null(dat.fronts)) return(NULL)

  p=plotLinearWeights(dat.fronts,input$timedependent)

  if(input$save!='NA'){
    fname=paste(subdir,paste('pareto',Probability(),Problem(),'phi',extension,sep='.'),sep='/')
    ggsave(fname,p,units=units,width=Width,height=Height.third)
  }
  return(p)
}, height="auto")

best.pref.models <- reactive({

  dat.fronts = Pareto.front()
  if(is.null(dat.fronts)) return(NULL)

  dat.fronts$BestInfo=interaction(dat.fronts$File,dat.fronts$NrFeat,dat.fronts$Model)
  best.model = ddply(dat.fronts,~Problem,summarise,Max.Accuracy.Optimality=BestInfo[Validation.Accuracy.Optimality==max(Validation.Accuracy.Optimality)],Min.Rho=BestInfo[Validation.Rho==min(Validation.Rho)])

  best=NULL
  for(i in 1:nrow(best.model))
  {
    tmp=subset(dat.fronts, Problem==best.model$Problem[i] & BestInfo==best.model$Max.Accuracy.Optimality[i])
    acc=subset(getOptimaltyAccuracy(tmp$File,F),NrFeat==tmp$NrFeat & Model==tmp$Model)
    acc=acc[,c('Step','validation.isOptimal')];colnames(acc)[2]='value'
    acc$Problem=tmp$Problem;
    acc$CDRlbl=tmp$CDRlbl
    acc$variable='Max.Accuracy.Optimality'
    acc$Accuracy='Optimality'
    best=rbind(best,acc)
    acc=subset(getPrefSetAccuracy(tmp$File,'Validation.Accuracy'),NrFeat==tmp$NrFeat & Model==tmp$Model)
    acc=acc[,c('Step','value')]
    acc$Problem=tmp$Problem;
    acc$CDRlbl=tmp$CDRlbl
    acc$variable='Max.Accuracy.Optimality'
    acc$Accuracy='Classification'
    best=rbind(best,acc)

    tmp=subset(dat.fronts, Problem==best.model$Problem[i] & BestInfo==best.model$Min.Rho[i])
    rho=subset(getOptimaltyAccuracy(tmp$File,F),NrFeat==tmp$NrFeat & Model==tmp$Model)
    rho=rho[,c('Step','validation.isOptimal')];colnames(rho)[2]='value'
    rho$Problem=tmp$Problem
    rho$CDRlbl=tmp$CDRlbl
    rho$variable='Min.Rho'
    rho$Accuracy='Optimality'
    best=rbind(best,rho)
    rho=subset(getPrefSetAccuracy(tmp$File,'Validation.Accuracy'),NrFeat==tmp$NrFeat & Model==tmp$Model)
    rho=rho[,c('Step','value')]
    rho$Problem=tmp$Problem
    rho$CDRlbl=tmp$CDRlbl
    rho$variable='Min.Rho'
    rho$Accuracy='Classification'
    best=rbind(best,rho)
  }

  return(list('Summary'=best.model,'Stepwise'=best))
})

output$plot.exhaust.best.diff <- renderPlot({

  best=best.pref.models()
  if(is.null(best)) { return(NULL) }

  best2=dcast(best$Stepwise,Step+Problem+Accuracy~variable,value.var = 'value')
  p=ggplot(best2,aes(x=Step,y=Max.Accuracy.Optimality-Min.Rho))+facet_grid(Accuracy~Problem,scale='free')+
    geom_hline(aes(yintercept=0),color='red')+geom_line()+
    ggplotColor("Best",2)+scale_size_discrete(range=c(0.5,1.2))

  if(input$save != 'NA'){
    fname=paste(paste(subdir,'trdat',sep='/'),'prob.moveIsOptimal',input$dimension,'OPT',Probability(),'best.diff',extension,sep='.')
    ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
  }
  return(p)
}, height="auto")

output$plot.exhaust.best <- renderPlot({

  Stepwise=dataset.Stepwise()
  best=best.pref.models()
  if(is.null(best)|is.null(Stepwise)) { return(NULL) }

  dimension=input$dimension

  p0=plotStepwiseOptimality(Stepwise,T,F)

  p=p0+facet_wrap(~Problem)+
    geom_line(data=best$Stepwise,aes(y=value,color=variable,size=Accuracy))+
    ggplotColor("Best",2)+scale_size_discrete(range=c(0.5,1.2))+ylab('Probability of CDR being optimal')+
    themeVerticalLegend

  if(input$save!='NA'){
    fname=paste(paste(subdir,'trdat',sep='/'),'prob.moveIsOptimal',dimension,'OPT',Probability(),'best',extension,sep='.')
    ggsave(p,filename=fname,width=Width,height=Height.half,units=units,dpi=dpi)
  }
  return(p)
}, height="auto")

output$table.paretoFront <- renderTable({
  return(liblinearXtable(Pareto.front()))
}, include.rownames=FALSE, sanitize.text.function=function(x){x})

ks.liblinearKolmogorov <- reactive({
  dat.fronts=Pareto.front()
  if(is.null(dat.fronts)){return(NULL)}
  liblinearKolmogorov(dat.fronts,input$problem,onlyPareto = F,SDR=NULL)
})

output$table.liblinearKolmogorov.Rho.train <- renderTable({
  ks=ks.liblinearKolmogorov()
  if(is.null(ks)){return(NULL)}
  return(ks$Rho.train)
},sanitize.text.function=function(x){x})
output$table.liblinearKolmogorov.Rho.test <- renderTable({
  ks=ks.liblinearKolmogorov()
  if(is.null(ks)){return(NULL)}
  return(ks$Rho.test)
},sanitize.text.function=function(x){x})
output$table.liblinearKolmogorov.Acc <- renderTable({
  ks=ks.liblinearKolmogorov()
  if(is.null(ks)){return(NULL)}
  return(ks$Acc)
},sanitize.text.function=function(x){x})
