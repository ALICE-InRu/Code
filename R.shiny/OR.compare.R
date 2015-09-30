source('global.R');source('cmaes.R')
OR.opt <- get.files.OPT(list.files('../../Data/OPT/','ORLIB.test.csv$'))
OR.opt=subset(OR.opt,!is.na(Optimum))
colnames(OR.opt)[grep('Optimum',colnames(OR.opt))]='BKS'

input=list(problem='j.rnd',problems=c('j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc','j.rnd_pj1doubled','j.rnd_p1mdoubled'))

or.vars=c('ORSet','GivenName','Dimension','BKS')
pickBest <- function(dat,cnt=1){
  if(cnt>0){
    best=ddply(subset(dat,!is.nan(Rho)),~Problem+ORSet+GivenName,
               function(x) head(x[x$Rho==min(x$Rho),],cnt))
  } else { best=subset(dat,!is.nan(Rho)) }
  best=join(OR.opt,best,type='right',by = c('Name','Problem','Set','PID','GivenName'))
  #fix = subset(best,Rho<0)
  #print(fix[,c(or.vars,'Problem','TrainingData','ObjFun','Makespan','Rho')])
  return(subset(best,Rho>=0))
}

CDR.CMA.orlib <- subset(get.CDR.CMA('j.rnd','10x10',times = F, testProblems = 'ORLIB'),Rho>=0)
CDR.CMA.orlib$ObjFun <- factor(CDR.CMA.orlib$ObjFun,
                               levels=c('min Cmax','min Rho'), labels=c('ES.Cmax','ES.rho'))
CDR.CMA.orlib$CDR='16.1'

files=list.files('../../Data/PREF//CDR/','ORLIB.test.csv',recursive = T)
files=files[grep('j.rnd.10x10',files)]
loc.files=files[grep('Globalweights|SDRweights',files,invert = T)]
glo.files=files[grep('Globalweights|SDRweights',files)]
PREF.local=unique(get.CDR(loc.files,set='ORLIB'))
PREF.global=unique(get.CDR(glo.files,set='ORLIB'))
PREF.global$RhoFort <- factorRho(PREF.global,'BestFoundMakespan')

cma.vars = c('ObjFun','CDR')
ddply(CDR.CMA.orlib,c('Problem',cma.vars),function(x) nrow(x))

pref.vars = c('Track','Bias','CDR')
levels(PREF.local$Supervision)=c('','UNSUP')
PREF.local$Track=interaction(PREF.local$Track,PREF.local$Supervision,sep='')
ddply(PREF.local,c('Problem',pref.loc.vars),function(x) nrow(x))
ddply(PREF.global,c('Problem',pref.glo.vars),function(x) nrow(x))

best.CMA <- pickBest(CDR.CMA.orlib)[,c(or.vars,c(cma.vars,'Rho'))]
head(best.CMA)
best.loc <- pickBest(PREF.local)[,c(or.vars,c(pref.vars,'Rho'))]
head(best.loc)
best.glo <- pickBest(PREF.global)[,c(or.vars,c(pref.vars,'RhoFort'))]
head(best.glo)


best=merge(best.loc,best.glo,by=or.vars,suffixes = c('Local','Global'))
best=merge(best.CMA,best,by=or.vars,suffixes = c('CMA','PREF'))
head(best)

best$Dimension=stringr::str_replace_all(best$Dimension,'x','&')
print(xtable(arrange(best,ORSet,GivenName)),include.rownames=F)

PREF.local=pickBest(PREF.local,0)
PREF.global=pickBest(PREF.global,0)
CDR.CMA.orlib=pickBest(CDR.CMA.orlib,0)

all <- rbind(data.frame(Type='PREF',
                        Problem=PREF.global$Problem,
                        GivenName=PREF.global$GivenName,
                        CDR=PREF.global$CDR,
                        Track=PREF.global$Track,
                        Bias=PREF.global$Bias,
                        Model=interaction(PREF.global$Track,PREF.global$Bias),
                        Rho=PREF.global$RhoFort),
             data.frame(Type='PREF',
                        Problem=PREF.local$Problem,
                        GivenName=PREF.local$GivenName,
                        CDR=PREF.local$CDR,
                        Track=PREF.local$Track,
                        Bias=PREF.local$Bias,
                        Model=interaction(PREF.local$Track,PREF.local$Bias),
                        Rho=PREF.local$Rho),
             data.frame(Type='CMA-ES',
                        Problem=CDR.CMA.orlib$Problem,
                        GivenName=CDR.CMA.orlib$GivenName,
                        CDR=CDR.CMA.orlib$CDR,
                        Track=CDR.CMA.orlib$ObjFun,
                        Bias='equal',
                        Model=CDR.CMA.orlib$ObjFun,
                        Rho=CDR.CMA.orlib$Rho))
all=subset(all,Rho>=0)
all$Problem <- factorProblem(all,F)
all$CDR<-factor(all$CDR,levels=sort(as.numeric(levels(all$CDR))))

if(F){
  ggplot(all,aes(x=CDR,y=Rho))+
    geom_boxplot(data=subset(all,Type=='PREF'),aes(color=Track,linetype=Bias))+
    geom_boxplot(data=subset(all,Type=='CMA-ES'),aes(color=Model))+
    scale_linetype_manual(values=c(2,1))+
    ggplotColor('Policy',length(levels(PREF.local$Track)))+themeBoxplot+ylab(bksLabel)+
    guides(color=guide_legend(nrow=2,byrow=TRUE),
           linetype=guide_legend(nrow=2,byrow=TRUE))+
    facet_grid(Problem~Type,scales='free',space = 'free')
  ggsave('../../Thesis/figures/boxplot.ORLIB.png',width = Width,height = Height.half,dpi=dpi,units=units)
}

all <- ddply(all,~GivenName,mutate,minRho=min(Rho))
ddply(all,~Type+CDR+Model,summarise,best_pct=round(100*mean(Rho==minRho),2),
      pct1=round(100*mean(Rho<=minRho+1),2),
      pct5=round(100*mean(Rho<=minRho+5),2),
      pct10=round(100*mean(Rho<=minRho+10),2))
