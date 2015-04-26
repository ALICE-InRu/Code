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
axisCompactY <- list(scale_y_continuous(expand=c(0,0)))
axisCompactX <- list(scale_x_continuous(expand=c(0,0)))
axisCompact <- list(axisCompactX, axisCompactY)
axisProbability <- list(axisCompactX, scale_y_continuous(limits=c(0,1), expand=c(0,0)))
axisStep <- function(dim){ list(expand_limits(x = c(1,numericDimension(dim)))) }

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

pref.boxplot <- function(CDR,SDR=NULL,ColorVar,xVar='CDR',xText='CDR',tiltText=T,lineTypeVar=NA){
  CDR=subset(CDR,!is.na(Rho))
  CDR$Problem=factorProblem(CDR)

  colnames(CDR)[grep(ColorVar,colnames(CDR))]='ColorVar'
  colnames(CDR)[grep(xVar,colnames(CDR))]='xVar'

  if(!is.na(lineTypeVar))
    colnames(CDR)[grep(lineTypeVar,colnames(CDR))]='lineTypeVar'

  if(!is.null(SDR)){
    SDR <- subset(SDR,Dimension %in% CDR$Dimension & Problem %in% CDR$Problem)
    SDR$xVar=SDR$SDR
  }
  p=ggplot(CDR,aes(x=as.factor(xVar),y=Rho))

  if(!is.na(lineTypeVar))
    p=p+geom_boxplot(aes(color=ColorVar,linetype=lineTypeVar))+scale_linetype(lineTypeVar)
  else
    p=p+geom_boxplot(aes(color=ColorVar))

  if(!is.null(SDR)){ p=p+geom_boxplot(data=SDR,aes(fill=SDR))+ggplotFill('SDR',4);}
  p=p+facet_grid(Set~Problem,scale='free_x') +
    ggplotColor(xText,length(unique(CDR$ColorVar))) +
    xlab('')+ylab(rhoLabel)+
    axisCompactY+expand_limits(y = 0)

  if(tiltText){ p=p+theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) }
  return(p)
}


clc <- function() cat(rep("\n",50)); clc()
