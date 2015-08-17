source('global.R')

get.procTimes <- function(problem,numJobs,numMacs){
  dimension=paste(numJobs,numMacs,sep='x')
  dat <- read.csv(paste0('../../Data/Raw/',problem,'.',dimension,'.train.txt'))
  proc = data.frame(matrix(vector(), numJobs, numMacs, dimnames=list(paste0('J',1:numJobs), paste0('M',1:numMacs))))
  for(job in 1:numJobs){
    proc[job,]=as.numeric(stringr::str_split(dat[4+job,],' ')[[1]])[seq(2,2*numMacs,2)]
  }
  proc$Problem=problem
  proc$Dimension=dimension
  proc$Job=rownames(proc)
  return(proc)
}

numJobs=6
numMacs=5
problems<-c('f.rnd','f.rndn','f.jc','f.mc','f.mxc')
dat <- do.call(rbind, lapply(problems,
                             function(problem) { get.procTimes(problem,numJobs,numMacs)} ))
mdat <- melt(dat,id.vars=c('Problem','Dimension','Job'),variable.name = 'Machine',value.name = 'Proc')
mdat$Problem <- factorProblem(mdat,F)
p <- ggplot(mdat,aes(y=Proc,x=Machine,color=Job))+geom_point()+
  facet_wrap(~Problem+Dimension,ncol=5,scales='free_y')+
  ggplotColor('Job',numJobs)+ylab(expression(p[ja]))+xlab('')
#+cornerLegend(length(problems),5)+guides(col = guide_legend(nrow = 2))
subdir='../../Thesis/figures';
save=F

if(save) ggsave(paste0(subdir,'/proctimes.pdf'),plot=p,width=Width*factor,height=55*factor,units=units,dpi=dpi)
