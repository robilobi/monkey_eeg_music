library(lme4)
library(emmeans)
library(effects) #for lmer
library(ggplot2)
library(car)
library(sjPlot)
library(webshot)
library(tidyverse)
library(ggpubr)
library(rstatix)
library(broom)

ls()
rm(list=ls())
getwd( )
setwd("../../data/eeg/TRF_PITCHONSET/")
data = read.csv( "PredAccTRFforstat_MONKEY.csv", header = F, sep = ',') 
colnames(data) <- c("monkey", "PredAcc","condition", "model", "melID", "PredAcc(A)") 

##########RENAME VARIABLES AND COLUMS
data$condition = as.factor(data$condition)
data$model = as.factor(data$model)
data$monkey= as.factor(data$monkey)
data$melID= as.factor(data$melID)
data$monkey = fct_recode(data$monkey, "Monkey 1" = "1", "Monkey 2" = "2")
data$condition = fct_recode(data$condition, "Original" = "1", "Shuffled" = "2")
data$model = fct_recode(data$model, "AM-A" = "1", "AMp-A" = "2", "AMo-A" = '3')
data$melID = fct_recode(data$melID, "s_01" = "11","s_05" = "12","s_08" = "13","s_10" = "14",
                        "o_05"= "5", "o_08"= "8", "o_03"= "3", "o_06"= "6", "o_04"= "4",
                        "o_09"= "9", "o_02"= "2", "o_01"= "1", "o_07"= "7", "o_10"= "10")
summary(data)

######### COMPARE FULL AND REDICED MODELS 
m.1= lmer(PredAcc~condition*model  +(1|monkey) + (1|melID),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)), data)
Anova(m.1, type=3)  #
emt = emmeans(m.1, pairwise~condition+model)
summary(emt)
plot_model(m.1, type = "pred", terms = c("model","condition"))+theme_classic()+ scale_color_manual(values=c("darkblue","red"))
ggsave(paste0("Estimates_TRF.pdf"), width = 4, height = 2)
ggsave(paste0("Estimates_TRF.png"), width = 4, height = 2)
tab_model(m.1, file = "stats_TRF.doc")

### only REAL MELODIES (TO COMPARE WITH HUMAN DATA)
dd = droplevels(data[data$condition=='Original',])
m.1= lmer(PredAcc~model  +(1|monkey) + (1|melID),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)), dd)
Anova(m.1, type=3)  #
emt = emmeans(m.1, pairwise~model)
summary(emt)
library(RColorBrewer)
darkcols <- brewer.pal(8, "Dark2")
plot_model(m.1, type = "pred", terms = c("model"))+theme_classic()+
  scale_color_manual(values=c(darkcols[6], darkcols[1]))+
  scale_fill_manual(values=c(darkcols[6], darkcols[1]))
ggsave(paste0("Estimates_TRF_onlyOriginal.pdf"), width = 4, height = 2)
ggsave(paste0("Estimates_TRF_onlyOriginal.png"), width = 4, height = 2)
tab_model(m.1, file = "stats_TRF_onlyOriginal.doc")

#########PLOT PRED ACC GAIN OF AM, AMP, AMT (ONLY REAL MELODIES)
ggplot(dd, aes(model, PredAcc))+
  theme_classic()+
  stat_summary(fun=mean, geom="point")+#coord_cartesian(ylim=c(0,0.1))+
  stat_summary(fun.data = 'mean_se', geom = "errorbar", width=0, alpha=0.6)+
  xlab("Model") + ylab("PredAcc")+ggtitle('')
ggsave(paste0("PredAcc_TRF_onlyOriginal.pdf"), width = 2, height = 2)


### ONE SAMPLE T-TEST: IS THERE A GAIN COMPARED WITH BASELINE ACOUSTIC MODEL 
ag=with(data, aggregate(cbind(`PredAcc(A)`,PredAcc ) ~model+melID, FUN="mean")) #aggregate across monkeys
ggplot(ag, aes(model, PredAcc))+#facet_grid(~monkey)+
  theme_minimal()+
  stat_summary(fun=mean, geom="point")+#coord_cartesian(ylim=c(0,0.1))+
  stat_summary( fun.data = 'mean_se', geom = "errorbar", width=0, alpha=0.6)+
  xlab("Model") + ylab("PredAcc")+ggtitle('')

model = droplevels(ag[ag$model=='AM-A',])
wilcox.test(model$PredAcc, mu = 0, alternative = "greater" )
model = droplevels(ag[ag$model=='AMp-A',])
wilcox.test(model$PredAcc, mu = 0, alternative = "greater" )
model = droplevels(ag[ag$model=='AMo-A',])
wilcox.test(model$PredAcc, mu = 0, alternative = "greater" )


ggplot(data, aes(model, PredAcc, group=condition, fill = condition, color = condition))+
  theme_minimal()+facet_grid(~monkey)+
  geom_jitter(aes(group=condition, color = condition),width = 0.1, size=0.5)+
  stat_summary(fun=mean, geom="line")+
  stat_summary(fun=mean, geom="point")+
  scale_color_manual(values=c("darkblue","red"))+
  stat_summary( fun.data = 'mean_se', geom = "errorbar", width=0, alpha=0.6)+
  xlab("Model") + ylab("PredAcc")+ggtitle('')
ggsave(paste0("PredAcc_TRF_onlyOriginal_BYCONDITIONandMONKEY.pdf"), width = 2, height = 2)

