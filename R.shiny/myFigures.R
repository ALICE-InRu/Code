Width=6.69291 #170mm
Height.quart=2.3622 #60mm
Height.third=3.14961 #80mm
Height.half=3.93701 #120mm
Height.full=8.66142 #220mm
units='in'

mainPalette <- function(n) {
  #palette <- c("red4", "darkslategray3", "dodgerblue1", "darkcyan", "skyblue2", "dodgerblue4", "purple4", "maroon", "chocolate1", "bisque3", "bisque", "seagreen4", "lightgreen", "skyblue4", "mediumpurple3", "palevioletred1", "lightsalmon4", "darkgoldenrod1")
  if (n <= 1)
    palette='black'
  else if (n <= 2)
    palette <- c("gray79", "black")
  else {
    library('RColorBrewer')
    palette = brewer.pal(min(9,n), name='Set1');
  }
  if (n > length(palette))
    warning('generated palette has duplicated colours')
  rep(palette, length.out=n)
}

extension='png'
subdir='figures/';
redoPlot=T;
dpi=300
#extension='pdf' # because if smooth is true eps doesn't work

mytheme <- theme_set(theme_bw())
mytheme <- theme_update(axis.text.y = element_blank(),
                        axis.line = element_blank(),
                        axis.title.x = element_blank(),
                        axis.title.y = element_blank(),
                        axis.ticks.x = element_blank(),
                        panel.grid.major = element_blank(),
                        panel.grid.minor = element_blank(),
                        panel.border = element_blank(),
                        panel.margin = unit(0.5,"lines") # margin between facets
)
theme_set(mytheme)
themeVerticalLegend <- theme_set(mytheme) # + theme(legend.position='right', legend.box = 'vertical')
mytheme <- theme_update(legend.justification='center',legend.position='bottom',legend.box = "horizontal")


#legend.justification='center',legend.position='right',legend.box = "vertical", # right
#legend.justification = c(1, 0),legend.position = c(1, 0),legend.box = "horizontal", # lower right hand corner

#ggplot <- function(...) ggplot2::ggplot(...) + scale_fill_brewer(palette=mainPalette) + scale_color_brewer(palette=mainPalette)
ggplotFill <- function(name,num,labels=NULL){
  mypalette = mainPalette(num);
  if(is.null(labels)){
    return(list(scale_fill_manual(values=mypalette,name=name)))
  } else {
    return(list(scale_fill_manual(values=mypalette,name=name,labels=labels)))
  }
}
ggplotColor <- function(name,num,labels=NULL){

  mypalette = mainPalette(num);
  if('OPT' %in% labels){ mypalette[grep('OPT',labels)]='#000000' }

  if(is.null(labels)){
    return(list(scale_color_manual(values=mypalette,name=name)))
  } else {
    return(list(scale_color_manual(values=mypalette,name=name,labels=labels)))
  }
}

ggplotCommon <- function(dat,xlabel='step',ylabel=NULL,probability=F,fullRange=F){

  l=list(guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
                colour = guide_legend(order=2, direction = "vertical", title.position = "top"),
                shape = guide_legend(order=3, direction = "vertical", title.position = "top"),
                size = guide_legend(order=4, direction = "vertical", title.position = "top")
  ))

  if(!is.null(ylabel)){
    l=list(l,ylab(ylabel))
  }

  if(probability==T){
    TightX=T
    if(fullRange){ l=list(l,coord_cartesian(ylim=c(0, 1)))}
    l=list(l,scale_y_continuous(expand=c(0,0), breaks=seq(0, 1, 0.25)))
  }

  if(!is.null(dat)){
    minStep=min(dat$Step)
    maxStep=max(dat$Step)
    discreteStep=25

    if(maxStep<discreteStep*2){
      discreteStep=10;
    }
    l=list(l,scale_x_discrete(expand = c(0, 0), limits=c(minStep,seq(discreteStep,maxStep,by=discreteStep),maxStep),xlabel))
  } else { l=list(l,xlab(xlabel))}

  return(l)
}

clc <- function() cat(rep("\n",50)); clc()
