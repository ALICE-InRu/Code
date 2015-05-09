source('global.R')
library(tidyr)
library(dplyr)

format <- function(x){
  pat='(?<Problem>[jf].[a-z1_]+).(?<Dimension>[0-9]+x[0-9]+).(?<RankPREF>[a-z].)?(?<Track>[0-9A-Z]+)'
  m=regexpr(pat,x$File,perl=T)
  x$Problem = getAttribute(x$File,m,which(attr(m,"capture.names")=='Problem'))
  x$Problem = factorProblem(x)
  x$Dimension = getAttribute(x$File,m,which(attr(m,"capture.names")=='Dimension'))
  x$Dimension = factorDimension(x)

  if(any(attr(m,"capture.names")[3]=='Rank')){
    x$Rank = getAttribute(x$File,m,'Rank'))
    x$Rank = factorRank(substr(x$Rank,1,1))
  }

  x$Track = getAttribute(x$File,m,'Track')
  x = factorTrack(x)

  if(all(grepl('diff',x$File))){
    pat='Local.diff.(?<RankPREF>[a-z])'
    m=regexpr(pat,x$File,perl=T)
    x$Rank = getAttribute(x$File,m,'RankPREF')
    x$Rank=factorRank(x$Rank)
  }

  if(all(grepl('weights',x$File))){
    pat='.(?<Bias>[a-z12]+).weights'
    m=regexpr(pat,x$File,perl=T)
    x$Bias = getAttribute(x$File,m,'Bias')
    x$Bias = factorBias(x$Bias)
    x$Timedependent = grepl('timedependent',x$File)
  }

  if(all(grepl('/',x$File))){
    pat='/(?<Problem>[jf].[a-z1_]+).(?<Dimension>[0-9]+x[0-9]+).(?<Set>test|train)'
    m=regexpr(pat,x$File,perl=T)
    x$ProblemApply = getAttribute(x$File,m,which(attr(m,"capture.names")=='Problem'))
    x$ProblemApply = factorProblem(x)
    x$DimensionApply = getAttribute(x$File,m,which(attr(m,"capture.names")=='Dimension'))
    x$DimensionApply = factorDimension(x)
    x$Set = factorSet(getAttribute(x$File,m,which(attr(m,"capture.names")=='Set')))
  }

  return(x)
}

training <- format(data.frame(File=list.files('../../Data/Training/','Local.csv')))
global <- format(data.frame(File=list.files('../../Data/Training/','Global.csv')))
diff <- format(data.frame(File=list.files('../../Data/Training/','diff.*.csv')))
pref <- format(data.frame(File=list.files('../../Data/PREF/weights/','.csv')))
rho.raw <- format(data.frame(File=list.files('../../Data/PREF/CDR/','.csv',recursive = T)))
rho.summary <- format(data.frame(File=list.files('../../Data/PREF/summary/','.csv',recursive = T)))

d.training = ddply(training, .(Dimension, Problem, Track, Supervision, Extended),
                   summarise, freq=length(Track))
d.global = ddply(global, .(Dimension, Problem, Track, Extended),
                 summarise, freq=length(Track))
d.diff = ddply(diff, .(Dimension, Problem, Track, Extended, Supervision),
               summarise, freq=length(Track))
d.pref = ddply(pref, .(Dimension, Problem, Bias, Track, Extended, Supervision, Timedependent),
               summarise, freq=length(Track))
d.rho.raw = ddply(rho.raw, .(Dimension, Problem, Bias, Track, Extended, Supervision, Timedependent),
              summarise, freq=length(Track))
d.rho.sum = ddply(rho.summary, .(Dimension, Problem, Bias, Track, Extended, Supervision, Timedependent),
                  summarise, freq=length(Track))

#subset(d.training, substr(Track,1,2) != 'IL') %>%  spread(Track, freq)
#subset(d.diff, substr(Track,1,2) != 'IL') %>%  spread(Track, freq)
#subset(d.pref, substr(Track,1,2) != 'IL') %>%  spread(Track, freq)
#d.global %>%  spread(Track, freq)

subset(d.training, substr(Track,1,2) == 'IL') %>%  spread(Track, freq)
subset(d.diff, substr(Track,1,2) == 'IL') %>%  spread(Track, freq)
subset(d.pref, substr(Track,1,2) == 'IL') %>%  spread(Track, freq)

subset(d.rho.raw, substr(Track,1,2) != 'IL') %>%  spread(Track, freq)
subset(d.rho.sum, substr(Track,1,2) != 'IL') %>%  spread(Track, freq)

subset(d.rho.raw, substr(Track,1,2) == 'IL') %>%  spread(Track, freq)
subset(d.rho.sum, substr(Track,1,2) == 'IL') %>%  spread(Track, freq)

for(dir in list.files('../../Data/PREF/CDR/','SUPEXT',full.names = T)){
  m=regexpr('full.(?<Problem>[j|f].[a-z]+).(?<Dimension>[0-9]+x[0-9]+).[a-z].IL(?<Iter>[0-9]+)',dir,perl=T)
  file=paste(dir,paste(getAttribute(dir,m,'Problem'),getAttribute(dir,m,'Dimension'),'train','csv',sep='.'),sep='/')
  dat=read.csv(file)
  iter=getAttribute(dir,m,3,F)
  maxPID = (iter+1)*ifelse(getAttribute(dir,m,'Dimension')=='6x5',500,300)
  dat=dat[1:maxPID,]
  write.csv(dat,file,row.names = F, quote = F)
}
