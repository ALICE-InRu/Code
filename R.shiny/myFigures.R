require(ggplot2)
require(gridExtra)

factor=1.2
Width=130*factor #170mm
Height.quart=43*factor #60mm
Height.third=61*factor #80mm
Height.half=87*factor #120mm
Height.full=175*factor #220mm
units='mm'
colorPalette='Set1'

mainPalette <- function(n) {
  library(RColorBrewer)
  getPalette = colorRampPalette(brewer.pal(9, colorPalette))

  #palette <- c("red4", "darkslategray3", "dodgerblue1", "darkcyan", "skyblue2", "dodgerblue4", "purple4", "maroon", "chocolate1", "bisque3", "bisque", "seagreen4", "lightgreen", "skyblue4", "mediumpurple3", "palevioletred1", "lightsalmon4", "darkgoldenrod1")
  if (n <= 1){
    palette='black'
  } else if (n <= 2) {
    palette <- c("gray79", "black")
  } else if(n <= 3) {
    palette = brewer.pal(5, 'Greys')[3:5] # first two are too light
  } else if (n>9) {
    palette = getPalette(n)
  } else {
    if(colorPalette=='Greys'){n=n+1}
    palette = brewer.pal(n, colorPalette)
    if(colorPalette=='Greys'){palette=palette[2:n]}
  }
  return(palette)
}

extension='png'
subdir='figures/';
redoPlot=T;
dpi=300
#extension='pdf' # because if smooth is true eps doesn't work

rhoLabel=expression("Deviation from optimality," * ~ rho * ~ " (%)")
bksLabel=expression("Deviation from best known solution," * ~ rho * ~ " (%)")

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
cornerLegend <- function(n,ncol=2){
  l <- list(guides(fill = guide_legend(order=1, direction = "vertical", title.position = "top"),
                   colour = guide_legend(order=2, direction = "vertical", title.position = "top")))
  if(n%%ncol==0|n==1){ return(l) }
    list(l, theme(legend.position = c(0.75, 1/(n*1.5)), legend.direction = "horizontal"),
         guides(linetype=guide_legend(ncol=1,title.position = 'top')))
}
mytheme <- theme_update(legend.justification='center',legend.position='bottom',legend.box = "horizontal")
axisCompactY <- list(scale_y_continuous(expand=c(0,0)))
axisCompactX <- list(scale_x_continuous(expand=c(0,0)))
axisCompact <- list(axisCompactX, axisCompactY)
axisProbability <- list(axisCompactX, scale_y_continuous(limits=c(0,1), expand=c(0,0)))
axisStep <- function(dim){ list(expand_limits(x = c(1,numericDimension(dim)))) }
themeBoxplot <- list(xlab(NULL),ylab(rhoLabel),axisCompactY,expand_limits(y = 0),
                     guides(fill = guide_legend(order=1),
                            color = guide_legend(order=2),
                            linetype = guide_legend(order=3)),
              # Hide all the vertical gridlines
              theme(panel.grid.minor.x=element_blank(),panel.grid.major.x=element_blank()))

#legend.justification='center',legend.position='right',legend.box = "vertical", # right
#legend.justification = c(1, 0),legend.position = c(1, 0),legend.box = "horizontal", # lower right hand corner

#ggplot <- function(...) ggplot2::ggplot(...) + scale_fill_brewer(palette=mainPalette) + scale_color_brewer(palette=mainPalette)
ggplotFill <- function(name,num,labels=NULL,values=NULL){
  myPalette = mainPalette(num);
  if('OPT' %in% labels){ myPalette[grep('OPT',labels)]='#000000' }
  if(!is.null(values)) { names(myPalette) = values }

  if(is.null(labels)){
    return(list(scale_fill_manual(values=myPalette,name=name)))
  } else {
    return(list(scale_fill_manual(values=myPalette,name=name,labels=labels)))
  }
}
ggplotColor <- function(name,num,labels=NULL,values=NULL){

  myPalette = mainPalette(num);
  if('OPT' %in% labels){ myPalette[grep('OPT',labels)]='#000000' }
  if(!is.null(values)) { names(myPalette) = values }

  if(is.null(labels)){
    return(list(scale_color_manual(values=myPalette,name=name)))
  } else {
    return(list(scale_color_manual(values=myPalette,name=name,labels=labels)))
  }
}

pref.boxplot <- function(CDR,SDR=NULL,ColorVar,xVar='CDR',xText='CDR',tiltText=T,lineTypeVar=NA){
  CDR=subset(CDR,!is.na(Rho))
  CDR$Problem=factorProblem(CDR,F)
  levels(CDR$Set)=paste(levels(CDR$Set),'set')

  colnames(CDR)[grep(ColorVar,colnames(CDR))]='ColorVar'
  colnames(CDR)[grep(xVar,colnames(CDR))]='xVar'

  if(!is.na(lineTypeVar))
    colnames(CDR)[grep(lineTypeVar,colnames(CDR))]='lineTypeVar'

  if(!is.null(SDR)){
    SDR <- subset(SDR,Name %in% CDR$Name)
    SDR$xVar=SDR$SDR
    levels(SDR$Set)=paste(levels(SDR$Set),'set')
  }

  if(is.numeric(CDR$xVar))
    p=ggplot(CDR,aes(x=xVar,group=xVar,y=Rho))
  else
    p=ggplot(CDR,aes(x=factor(xVar),y=Rho))

  if(!is.na(lineTypeVar))
    p=p+geom_boxplot(aes(color=ColorVar,linetype=lineTypeVar))+scale_linetype(lineTypeVar)
  else
    p=p+geom_boxplot(aes(color=ColorVar))

  if(!is.null(SDR)){
    p = p + geom_boxplot(data=SDR,aes(fill=SDR))+
      ggplotFill('SDR',length(sdrs)) + guides(fill=guide_legend(nrow=2,byrow=FALSE))
  }
  p=p+facet_grid(Set~Problem,scales='free_x', space = 'free_x') +
    ggplotColor(xText,length(unique(CDR$ColorVar))) + themeBoxplot

  if(tiltText){ p=p+theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) }
  return(p)
}

clc <- function() cat(rep("\n",50)); clc()
