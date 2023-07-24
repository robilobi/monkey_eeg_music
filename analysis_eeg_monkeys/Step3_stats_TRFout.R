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
library(plyr)
library(lubridate)
library(dplyr)


ls()
rm(list=ls())

setwd("../../data/eeg/")
data = read.csv( "TRFout_r_stat.csv", header = F, sep = ',') 
colnames(data) <- c("monkey", "PredAcc","condition", "model", "melID", "PredAcc(A)") 

stimdir = "../../data/stimuli/"
stimfl = paste0(stimdir, "IDYOMvalues.csv")

##########RENAME COLUMS
data$condition = as.factor(data$condition)
data$model = as.factor(data$model)
data$monkey= as.factor(data$monkey)
data$melID= as.factor(data$melID)
data$monkey = fct_recode(data$monkey, "Monkey 1" = "1", "Monkey 2" = "2")
data$condition = fct_recode(data$condition, "Original" = "1", "Shuffled" = "2")
data$model = fct_recode(data$model, "AM-A" = "1", "AMc-A" = "2")
data$melID = fct_recode(data$melID, "s_01" = "11","s_05" = "12","s_08" = "13","s_10" = "14",
                        "o_05"= "5", "o_08"= "8", "o_03"= "3", "o_06"= "6", "o_04"= "4",
                        "o_09"= "9", "o_02"= "2", "o_01"= "1", "o_07"= "7", "o_10"= "10")
summary(data)

#####CORRELATE A PRED ACC AND TIMING SURPRISE VALUES (SANITY CHECK AS IN DILIB 2020)
surprise = read.csv(stimfl)
surprise$melID = surprise$melody.name
predA=with(data, aggregate(cbind(`PredAcc(A)`) ~ condition+melID, FUN="mean")) #
stim = merge(surprise, predA, by = c('melID'))
stim$rvalues = stim$`PredAcc(A)`
cor.test(stim$rvalues, stim$onset.information.content, method=c("spearman"))
cor.test(stim$rvalues, stim$cpitch.information.content, method=c("spearman"))
cor.test(stim$rvalues, stim$information.content, method=c("spearman"))

cor.test(stim$rvalues, stim$onset.entropy, method=c("spearman"))
cor.test(stim$rvalues, stim$cpitch.entropy, method=c("spearman"))
cor.test(stim$rvalues, stim$entropy, method=c("spearman"))

library("ggpubr")
ggscatter(stim, x = "onset.information.content", y = "rvalues", 
          #add = "reg.line", conf.int = F, 
          color = "condition", palette = "jco",           
          cor.coef = TRUE, cor.method = "spearman",
          xlab = "S timing", ylab = "A model Pred. Acc. (r)")+
          scale_color_manual( values=c("darkblue", "red"))
wilcox.test(rvalues ~ condition, data = stim, paired=FALSE, exact=FALSE, conf.int=TRUE)


#### COMPARE MODELS AND PLOT FIT AND TRF R VALUES
m.1= lmer(PredAcc~condition*model  +(1|monkey) + (1|melID),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)), data)
Anova(m.1, type=3)  #
emt = emmeans(m.1, pairwise~condition+model)
summary(emt)

bmp(file="Estimates_TRF.bmp",width=3, height=3, units="in", res=300)
plot_model(m.1, type = "pred", terms = c("model","condition"))+theme_classic()+ scale_color_manual(values=c("darkblue","red"))
ggsave(paste0("Estimates_TRF.pdf"), width = 3, height = 3)
dev.off()
tab_model(m.1, file = "stats_TRF.doc")

######### PLOT PRED ACC GAIN AM VS AMC MODEL IN SHUFFLED AND REAL MELODIES
data$model=relevel(data$model, ref='AM-A')
ggplot(data, aes(x = model, y =PredAcc, fill = condition, lty = model)) +
  theme_classic()+facet_grid(~monkey)+
  stat_summary(fun ="mean", geom="bar", position="dodge")+
  stat_summary(geom = "errorbar", fun.data = mean_cl_boot, position = position_dodge(0.9), size=.3, width =0)+
  # scale_color_manual(values=c("darkblue","red"))+
  scale_fill_manual(values=c("darkblue","red"))+
  xlab("Model") + ylab("PredAcc")+ggtitle('')
ggsave(paste0("FIG_PREDACCBYCON_BARPLOT.pdf"), width = 5, height = 5)

######## SHOW INDIVIDUAL DATA POINTS (= MELODIES)
ggplot(data, aes(condition, PredAcc, group=model, lty =model))+
  theme_minimal()+facet_grid(~monkey)+
  geom_jitter(aes(group=condition, color = condition),width = 0.1, size=0.5)+
  stat_summary(fun=mean, geom="line")+
  stat_summary(fun=mean, geom="point")+
  scale_color_manual(values=c("darkblue","red"))+
  stat_summary( fun.data = 'mean_se', geom = "errorbar", width=0, alpha=0.6)+
  xlab("Model") + ylab("PredAcc")+ggtitle('')
ggsave(paste0("FIG_PREDACCBYCOND.pdf"), width = 3, height = 3)


   
###########PLOT PRED ACC GAIN OF AM MODEL BY MELODY RANKED BY MEAN SURPRISE 
level_mel =c("s_05", "s_01", "s_08", "s_10", "o_05", "o_08", "o_03", "o_06", "o_04", "o_09", "o_02", "o_01", "o_07", "o_10")
ag <- data %>% 
  arrange(factor(melID, levels = level_mel))
ag$condition=fct_relevel(ag$condition, "Shuffled", "Original")
  ggplot()+
    geom_line(data = ag, aes(y = PredAcc, x =factor(melID, levels = level_mel), group= interaction(condition,model), color= condition, lty=model))+
    geom_point(data = ag, aes(y = PredAcc, x =factor(melID, levels = level_mel), group= interaction(condition,model), color= condition,lty=model))+
    facet_grid(~monkey)+
    theme_classic()+xlab("Musical piece") + ylab("Delta Pred. Acc. (r)")+ggtitle('')+ 
    theme(axis.text.x=element_text(angle=45,hjust=1)) +scale_color_manual(values=c("red","darkblue"))+theme(legend.position = 'bottom')
ggsave("FIG_modelDiffbyMel.pdf", width = 7.5, height = 4)

#########PLOT PRED ACC A MODEL (BASELINE BY MELODY)
ag$condition=fct_relevel(ag$condition, "Shuffled", "Original")
ag2=with(data, aggregate(cbind(`PredAcc(A)`) ~ condition+melID+monkey, FUN="mean")) #
ag2$condition=fct_relevel(ag2$condition, "Shuffled", "Original")
ggplot(data = ag2, aes(y = `PredAcc(A)`, x =factor(melID, levels = level_mel), group= condition, color= condition, fill=condition))+
  geom_bar(stat="identity")+  facet_grid(~monkey)+ theme_classic()+xlab("Musical piece") + 
  ylab("Pred. Acc.: A model (r)")+ggtitle('')+ theme(axis.text.x=element_text(angle=45,hjust=1))+
  scale_color_manual(values=c("white","white"))+scale_fill_manual(values=c("red","darkblue"))+theme(legend.position = 'bottom')
ggsave("FIG_modelAbyMel.pdf", width = 7.5, height = 3)


########PLOT PRED ACC GAIN ACROSS MONKEYS PER EACH MELODY
ag$condition=fct_relevel(ag$condition, "Shuffled", "Original")
ag2=with(data, aggregate(cbind(`PredAcc(A)`) ~ condition+melID+monkey, FUN="mean")) #
ag2$condition=fct_relevel(ag2$condition, "Shuffled", "Original")
ggplot(data = ag2, aes(y = `PredAcc(A)`, x =factor(melID, levels = level_mel), 
                       group= interaction(condition,monkey), color= condition, fill=condition, lty = monkey))+
  theme_classic()+xlab("Musical piece") + geom_line()+geom_point()+
  scale_color_manual(values=c("red","darkblue"))+theme(legend.position = 'bottom')+
  ylab("Pred. Acc.: A model (r)")+ggtitle('')+ theme(axis.text.x=element_text(angle=45,hjust=1))
