library(lmerTest)
library(emmeans)
library(effects) #for lmer
library(ggplot2)
library(car)
library(sjPlot)
library(webshot)
library(tidyverse)
library(rstatix)
library(ggdist) # half violinn plot 

ls()
rm(list=ls())
dir0 =  getwd()
source(paste0(dir0, "/fun_plot_geom_flat_violin.R"))

setwd("../../data/pupillometry/")
filename = "Pupildata_monkeys_timebin05s"
data = read.csv( paste0(filename, ".csv"), header = T, sep = ';') 


##########LINEAR MIXED MODEL
####run different fits to the data
data$bin = as.numeric(data$bin)
data$Melody=as.factor(data$Melody)
data$condition = as.factor(data$condition)
data$condition = fct_recode(data$condition,  "Shuffled" = "2","Original" = "1")
data$session= as.numeric(data$session)
data$monkey= as.factor(data$monkey)
data$monkey = fct_recode(data$monkey, "Mk1" = "1", "Mk2" = "2")
data$Melody= as.factor(data$Melody)
summary(data)


### PLOT PERCENTAGE OF NAA
perc= data %>%
  group_by(monkey, session, Melody) %>%
  summarise(na.prop = length(which(is.na(PupilSize)))/length(PupilSize))
ggplot(perc, aes(session, na.prop, group = Melody, color = Melody))+theme_classic()+facet_grid(~monkey)+
  geom_point()+ geom_hline(yintercept = 0.8, color='red')
ggsave(paste0("plot_percNAN_", filename, '.pdf'), width = 7, height = 5)


data = data %>%  # filtered data
  group_by(monkey, session, Melody) %>%
  mutate(sess.flag = ifelse(length(which(is.na(PupilSize)))/length(PupilSize)>0.8,1,0)) %>%
  filter(sess.flag==0) ### keep the melody if there are at least 30 sec of data 


######### USE FILTERED  data
data$Time = data$bin
data$Time = (data$Time*0.5)
# ZSCORE DATA BY MONKEY BY SESSION 
data$Melody= as.factor(data$Melody)
data$session= as.factor(data$session)
data = data %>% 
  group_by(monkey, session) %>%
  mutate(PupilSizez = (PupilSize - mean(PupilSize, na.rm=T))/sd(PupilSize, na.rm=T))

# hist data how many melody remains by session
ag=with(data, aggregate(cbind(PupilSizez) ~ condition+Melody+session+monkey, FUN="median", na.rm = TRUE)) #
table(ag$condition, ag$monkey, ag$session)
ag %>%
  ggplot( aes(x=Melody, fill=condition)) +facet_grid(~monkey)+theme_classic()+
  geom_bar( color="#e9ecef", alpha=0.6, position = 'identity') +
  scale_fill_manual(values=c("darkblue", "red"))+
  labs(fill="")

# AVERAGE MELODY BY SESSIONS (MEDIAN)
ag=with(data, aggregate(cbind(PupilSizez, PupilSize) ~ monkey+condition+Melody+bin+Time, FUN="median")) #
# LMER CONDITION * BIN ON DATA AGGREGATED BY SESSION
m.1= lmer(PupilSizez~condition*scale(bin) +(1|monkey) + (1|Melody) ,
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)),
          contrasts = list(condition='contr.sum'),
          ag)
Anova(m.1, type=3); 
summary(m.1)  

emt = emmeans(m.1, pairwise~condition); summary(emt)
emt = emtrends(m.1, pairwise~condition, var = 'bin', infer = c(T, T)); summary(emt)
plot_model(m.1, type = "pred", terms = c( "bin", "condition"))+
  theme_minimal()+  
  scale_color_manual(values=c("darkblue", "red"))+
  scale_fill_manual(values=c("darkblue", "red"))+
  ylab("Estimates Pupil size (a.u.)")
ggsave(paste0("plot_estimates_pupil_", filename, '.pdf'), width = 7, height = 5)
tab_model(m.1, file = "stats_pupil.doc")

ggplot(ag, aes(Time, PupilSizez, group = condition, fill = condition, color = condition))+
  theme_classic()+scale_color_manual(values=c("darkblue", "red"))+
  scale_fill_manual(values=c("darkblue", "red"))+  
  facet_wrap(~ monkey, scales='free')+
  geom_smooth(aes(fill=condition), method = 'loess') + ylab("Pupil size Mean (a.u.)") + xlab("Time (s)") +
  theme(legend.position= c(.85, .85))
ggsave(paste0("plot_condBybin_", filename, '.pdf'), width = 7.5, height = 3)



# LMER ON NON AGGREGATED DATA CORRECTING FOR GAZE
m.1= lmer(PupilSizez~condition*scale(bin)+session+datagzy+datagzx  +(1|monkey) + (1|Melody),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)),
          contrasts = list(condition='contr.sum'),
          data)
Anova(m.1, type=3)  
summary(m.1)
plot_model(m.1, type = "pred", terms = c( "bin" , "condition"))+
  theme_minimal()+  
  scale_color_manual(values=c("darkblue", "red"))+
  scale_fill_manual(values=c("darkblue", "red"))+
  ylab("Estimates Pupil size (a.u.)")
emt = emmeans(m.1, pairwise~condition);summary(emt)
emt = emtrends(m.1, pairwise~condition, var = 'bin', infer = c(T, T)); summary(emt)



# CONTROL ANALYSIS WITH MATCHED MELODIES 
dd = data[data$Melody == c(1,5,8,10,11,12,13,14),] # matched original vs shuffled melodies
ag=with(dd, aggregate(cbind(PupilSize, PupilSizez) ~ monkey+condition+Melody+bin, FUN="median")) #
# summar statistics
ag%>%
  group_by(condition, monkey) %>%
  get_summary_stats(PupilSize, type = "mean_sd")
# NON PARAMETRIC TEST
wilcox.test(PupilSizez ~ condition, data = ag[ag$monkey=='Mk1',], paired=T, exact=FALSE, conf.int=TRUE)
wilcox.test(PupilSizez ~ condition, data = ag[ag$monkey=='Mk2',], paired=T, exact=FALSE, conf.int=TRUE)

ggplot(ag, aes(monkey,PupilSizez, fill=condition)) + theme_minimal()+
  stat_slab(aes(thickness = after_stat(pdf*n)), scale = 0.7, alpha = 0.2)+  
  geom_boxplot(width = .2, alpha = 1, fatten = NULL, show.legend = T) +
  stat_summary(fun.data = "mean_se", geom = "pointrange", show.legend = F, 
               position = position_dodge(.175)) +
  scale_color_manual(values=c("darkblue", "red"))+
  scale_fill_manual(values=c("darkblue", "red"))+
  xlab("") + ylab("Pupil Width (a.u.) ")+theme(legend.position="bottom")
ggsave(paste0("plot_cond_", filename, '.pdf'), width = 7, height = 5)


ag=with(dd, aggregate(cbind(PupilSizez) ~ monkey+condition+Melody+bin, FUN="median")) #
m.1= lmer(PupilSizez~condition*scale(bin) + (1|monkey) + (1|Melody) ,
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)),
          contrasts = list(condition='contr.sum'),
          ag)
Anova(m.1, type=3); 
summary(m.1)  
emt = emmeans(m.1, pairwise~condition); summary(emt)
emt = emtrends(m.1, pairwise~condition, var = 'bin', infer = c(T, T)); summary(emt)
plot_model(m.1, type = "pred", terms = c( "bin", "condition"))+
  theme_minimal()+  
  scale_color_manual(values=c("darkblue", "red"))+
  scale_fill_manual(values=c("darkblue", "red"))+
  ylab("Estimates Pupil size (a.u.)")

ggplot(ag, aes(bin, PupilSizez, group = condition, fill = condition, color = condition))+
  theme_classic()+scale_color_manual(values=c("darkblue", "red"))+
  scale_fill_manual(values=c("darkblue", "red"))+  facet_wrap(~ monkey, scales='free')+
  geom_smooth(aes(fill=condition), method = 'loess') + ylab("Pupil size Mean (a.u.)") + xlab("Time (s)") +
  theme(legend.position= c(.85, .85))

