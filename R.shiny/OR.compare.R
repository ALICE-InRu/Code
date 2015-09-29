source('global.R');source('cmaes.R')
OR.opt <- get.files.OPT(list.files('../../Data/OPT/','ORLIB.test.csv$'))
OR.opt=subset(OR.opt,!is.na(Optimum))
colnames(OR.opt)[grep('Optimum',colnames(OR.opt))]='BKS'

input=list(problem='j.rnd',problems=c('j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc','j.rnd_pj1doubled','j.rnd_p1mdoubled'))

CDR.CMA.orlib <- do.call(rbind, lapply(c('6x5','10x10'), function(dim){
  get.CDR.CMA(input$problems,dim,times = F, testProblems = 'ORLIB') }))
best=ddply(subset(CDR.CMA.orlib,!is.nan(Rho)),~Problem+ORSet+GivenName,
           function(x) head(x[x$Rho==min(x$Rho),],1))
best=join(OR.opt,best,type='right',by = c('Name','Problem','Set','PID','GivenName'))
fix = subset(best,Rho<0)
fix[,c('Problem','ORSet','GivenName','Dimension','BKS','TrainingData','ObjFun','Makespan','Rho')]
best=subset(best,Rho>=0)
best=best[,c('ORSet','GivenName','Dimension','BKS','TrainingData','ObjFun','Rho')]
print(xtable(arrange(best,ORSet,GivenName)),include.rownames=F)

files=list.files('../../Data/PREF//CDR/','ORLIB.test.csv',recursive = T)
loc.files=files[grep('Globalweights|SDRweights',files,invert = T)]

PREF.local=get.CDR(loc.files,set='ORLIB')
PREF.global=get.CDR(files[grep('Globalweights|SDRweights',files)],set='ORLIB')

ddply(PREF.local,~Problem+Set+Rank+Track+Bias+CDR+Iter+Extended,function(x) nrow(x))
