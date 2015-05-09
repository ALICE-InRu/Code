require(ggplot2)
require(gridExtra)

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
    palette = RColorBrewer::brewer.pal(min(9,n), name='Set1')
  }
  if (n > length(palette)) {
    palette = c(palette, RColorBrewer::brewer.pal(min(8,n), name='Set2'))
  }
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

  if(!is.null(SDR)){ p=p+geom_boxplot(data=SDR,aes(fill=SDR))+ggplotFill('SDR',length(sdrs));}
  p=p+facet_grid(Set~Problem,scale='free_x') +
    ggplotColor(xText,length(unique(CDR$ColorVar))) +
    xlab('')+ylab(rhoLabel)+
    axisCompactY+expand_limits(y = 0)

  if(tiltText){ p=p+theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) }
  return(p)
}

grid_arrange_shared_legend <- function(...) {
  plots <- list(...)
  g <- ggplotGrob(plots[[1]] + theme(legend.position="bottom"))$grobs
  legend <- g[[which(sapply(g, function(x) x$name) == "guide-box")]]
  lheight <- sum(legend$height)
  grid.arrange(
    do.call(arrangeGrob, lapply(plots, function(x)
      x + theme(legend.position="none"))),
    legend,
    ncol = 1,
    heights = unit.c(unit(1, "npc") - lheight, lheight))
}

#dsamp <- diamonds[sample(nrow(diamonds), 1000), ]
#p1 <- qplot(carat, price, data=dsamp, colour=clarity)
#p2 <- qplot(cut, price, data=dsamp, colour=clarity)
#p3 <- qplot(color, price, data=dsamp, colour=clarity)
#p4 <- qplot(depth, price, data=dsamp, colour=clarity)
#grid_arrange_shared_legend(p1, p2, p3, p4)

grid_arrange_different_yaxis <- function(p1, p2, panel_num){

  p1 <- p1 + axisCompactX +
    theme(legend.position = 'bottom', plot.margin = unit(c(1, 2, 0.5, 0.5), 'cm'))
  p2 <- p2 + axisCompactX +
    theme(legend.position = 'bottom', plot.margin = unit(c(1, 2, 0.5, 0.5), 'cm'))

  # extract gtable
  g1 <- ggplot_gtable(ggplot_build(p1))
  g2 <- ggplot_gtable(ggplot_build(p2))

  combo_grob <- g2
  #pos <- length(combo_grob) - 1
  #combo_grob$grobs[[pos]] <- cbind(g1$grobs[[pos]], g2$grobs[[pos]], size = 'first')

  for (i in seq(panel_num))
  {
    #grid.ls(g1$grobs[[i + 1]])
    panel_grob <- getGrob(g1$grobs[[i + 1]], 'GRID.polyline',
                          grep = TRUE, global = TRUE)
    combo_grob$grobs[[i + 1]] <- addGrob(combo_grob$grobs[[i + 1]],
                                         panel_grob)
  }


  pos_a <- grep('axis_l', names(g1$grobs))
  axis <- g1$grobs[pos_a]
  for (i in seq(along = axis))
  {
    if (i %in% c(2, 4))
    {
      pp <- c(subset(g1$layout, name == paste0('panel-', i), se = t:r))

      ax <- axis[[1]]$children[[2]]
      ax$widths <- rev(ax$widths)
      ax$grobs <- rev(ax$grobs)
      ax$grobs[[1]]$x <- ax$grobs[[1]]$x - unit(1, "npc") + unit(0.5, "cm")
      ax$grobs[[2]]$x <- ax$grobs[[2]]$x - unit(1, "npc") + unit(0.8, "cm")
      combo_grob <- gtable_add_cols(combo_grob, g2$widths[g2$layout[pos_a[i],]$l], length(combo_grob$widths) - 1)
      combo_grob <- gtable_add_grob(combo_grob, ax,  pp$t, length(combo_grob$widths) - 1, pp$b)
    }
  }

  pp <- c(subset(g1$layout, name == 'ylab', se = t:r))

  ia <- which(g1$layout$name == "ylab")
  ga <- g1$grobs[[ia]]
  ga$rot <- 270
  ga$x <- ga$x - unit(1, "npc") + unit(1.5, "cm")

  combo_grob <- gtable_add_cols(combo_grob, g2$widths[g2$layout[ia,]$l], length(combo_grob$widths) - 1)
  combo_grob <- gtable_add_grob(combo_grob, ga, pp$t, length(combo_grob$widths) - 1, pp$b)
  combo_grob$layout$clip <- "off"

  grid.draw(combo_grob)

}

grid_arrange_shared_xaxis <- function(p1, p2){
  p1<- p1 + axisCompactX +
    theme(plot.margin = unit(c(-1,0.5,0.5,0.5), "lines"))

  p2<- p2 + xlab('') + axisCompactX +
    theme(axis.text.x=element_blank(),
          axis.title.x=element_blank(),
          plot.title=element_blank(),
          axis.ticks.x=element_blank(),
          plot.margin = unit(c(0.5,0.5,-1,0.5), "lines"))

  gp1<- ggplot_gtable(ggplot_build(p1))
  gp2<- ggplot_gtable(ggplot_build(p2))
  maxWidth = unit.pmax(gp1$widths[2:3], gp2$widths[2:3])
  gp1$widths[2:3] <- maxWidth
  gp2$widths[2:3] <- maxWidth
  grid.arrange(gp2, gp1)
}


clc <- function() cat(rep("\n",50)); clc()
