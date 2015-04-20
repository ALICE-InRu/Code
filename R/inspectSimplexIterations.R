inspectSimplexIterations <- function(dat, redo=F){
  figSimplex='figures/simplex.pdf'
  if(file.exists(figSimplex)&!redo){return();}
  
  dat$Step = as.numeric(dat$Step)
  
  library('plyr')
  library('ggplot2')
  library('RColorBrewer')
  theme_set(theme_bw())
    
  mypalette = brewer.pal(n=length(levels(dat$Track))+1, name='BuPu'); 
  mypalette = mypalette[2:length(mypalette)]
  
  ggplot <- function(...) ggplot2::ggplot(...) + scale_color_manual(values=mypalette) +
    theme(legend.position="bottom", 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank()) +       
    scale_x_discrete(expand = c(0, 0), limits=c(min(dat$Step),seq(5,max(dat$Step),by=5),max(dat$Step)),'step')
    
  Simplex.stats=ddply(subset(dat, Followed==T),~Problem+Step+Track, summarise, simplex.mean = mean(Simplex))  
  p <- ggplot(Simplex.stats,aes(x=as.numeric(Step),y=simplex.mean,colour=Track))
  p <- p+theme_bw()+facet_wrap(~Problem, ncol=2, scales="free_y")
  p <- p+geom_line()
  p <- p + ylab('Simplex iterations (mean)')  
  p <- p + theme(legend.justification=c(1,0), legend.position=c(1,0))  # legend bottom right corner  
  # log10 with exponents on tick labels
  # p <- p+scale_y_continuous(trans=log10_trans(),breaks = trans_breaks("log10", function(x) 10^x),labels = trans_format("log10", math_format(10^.x)))  
  ggsave(figSimplex,p)        
  
  return(p)
}
