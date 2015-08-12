source('global.R')
source('gantt.R')
subdir='../../Thesis/figures';
save=F

problem='j.rnd'
dim='4x5'
tracks=c(sdrs,'OPT')

all.gantt <- do.call(rbind, lapply(tracks, function(sdr){get.gantt(problem,dim,sdr,1)}))
p <- plot.gantt(all.gantt,numericDimension(dim))
if(save) ggsave(paste0(subdir,'/example.gantt.SDRs.eps'),plot=p,width=Width,height=Height.full)

gantt=get.gantt(problem,dim,'SPT',1)
p <- plot.gantt(gantt,10,T,T,T)
if(save) ggsave(paste0(subdir,'/example.gantt.pdf'),plot=p,width=Width,height=Height.half)

#gantt.1=get.gantt(problem,dim,'RND',1);gantt.1=subset(gantt.1,Step<=1);plot.gantt(gantt.1,1,TightTime = T)
#gantt.2=get.gantt(problem,dim,'RND',1);gantt.2=subset(gantt.2,Step<=1);plot.gantt(gantt.2,1,TightTime = T)
#gantt.3=get.gantt(problem,dim,'RND',1);gantt.3=subset(gantt.3,Step<=1);plot.gantt(gantt.3,1,TightTime = T)
#gantt.41=get.gantt(problem,dim,'RND',1);gantt.41=subset(gantt.41,Step<=2);plot.gantt(gantt.41,2,TightTime = T)
#gantt.42=get.gantt(problem,dim,'SPT',1);plot.gantt(gantt.42,2,TightTime = T);gantt.42=subset(gantt.42,Step<=2)
#gantt.43=get.gantt(problem,dim,'RND',1);gantt.43=subset(gantt.43,Step<=2);plot.gantt(gantt.43,2,TightTime = T)
#gantt.44=get.gantt(problem,dim,'RND',1);gantt.44=subset(gantt.44,Step<=2);plot.gantt(gantt.44,2,TightTime = T)

gantt.0<-subset(gantt.42,Step==0)
gantt.4<-subset(gantt.42,Step<=1)

gantt.0$Track='empty schedule'
gantt.1$Track='J1'
gantt.2$Track='J2'
gantt.3$Track='J3'
gantt.4$Track='J4'
gantt.41$Track='J4 J1'
gantt.42$Track='J4 J2'
gantt.43$Track='J4 J3'
gantt.44$Track='J4 J4'

p0=plot.gantt(gantt.0,0,TightTime = T)+scale_x_continuous('',expand = c(0,0))
p1=plot.gantt(rbind(gantt.1,gantt.2,gantt.3,gantt.4),1,TightTime = T)+scale_x_continuous('',expand = c(0,0))
p2=plot.gantt(rbind(gantt.41,gantt.42,gantt.43,gantt.44),2,TightTime = T)+scale_x_continuous('Time',expand = c(0,0))

require(gridExtra)
if(save) pdf(paste(subdir,'gametree.pdf',sep='/'),width = Width, height = Height.full)
grid.arrange(p0, p1, p2, ncol=1)
if(save) dev.off()

subdir=paste(subdir,'animation',sep='/')
lapply(tracks, function(track){ gif.gantt(problem,dim,track)})
