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
library(performance)


ls()
rm(list=ls())
dirbase = "C:/Users/robianco/OneDrive - Fondazione Istituto Italiano Tecnologia/BACHMK/RESULTS/PreprocessedEEG5/ONSETS/"
dir = "C:/DATAVERSE/Monkeys/eeg/"
dir = paste0(dirbase, "Surprise/")
setwd(dir)
data = read.csv(paste0(dir, "ERPMatrix_integrale_PitchOnset.csv"), header = F, sep = ',') 
#data = read.csv(paste0(dir, "ERPMatrix_mean_PitchOnset.csv"), header = F, sep = ',') 
colnames(data) <- c("monkey", "session","cond", "ITI", "IOI","Surprise", "melID", "P1","CNV", "none","trial", "Sp", "So") 
data$cond = as.factor(data$cond)
data$melID= as.factor(data$melID)
data$monkey= as.factor(data$monkey)
data$monkey = fct_recode(data$monkey, "Monkey 1" = "1", "Monkey 2" = "2")
data$cond = fct_recode(data$cond, "S low" = "1", "S high" = "2")
data$cond = fct_relevel(data$cond, "S low")
Original = c(101:110)
#Original = c(101, 105, 108, 110)
Shuffled = c(111, 115, 118, 120)
data$type[data$melID %in% Original] = 'Original'
data$type[data$melID %in% Shuffled] = 'Shuffled'
data$type = as.factor(data$type)
summary(data)
head(data)
library("PerformanceAnalytics")
datacorr = data[data$monkey== "Monkey 1"  & data$session ==1,]
my_data <- datacorr[, c(4,5,6, 12, 13)]
bmp(file="plot_corrIOIS.bmp",width=6, height=6, units="in", res=300)
chart.Correlation(my_data, histogram=TRUE, pch=19)
dev.off()


##########LINEAR MIXED MODEL
####run different fits to the data
notes = droplevels(data[data$monkey== "Monkey 1" & data$session ==1,])
bmp(file="plot_Surprise_byCond_hist.bmp",width=6, height=3, units="in", res=300)
notes$type = as.factor(notes$type)
notes$type=fct_relevel(notes$type, "Shuffled", "Original")
ggplot(notes, aes(x=Surprise, color=cond, fill = cond)) +
  scale_color_manual(values=c("yellow","purple"))+facet_wrap(~type)+
  geom_histogram(fill="white",alpha=0.5, position="dodge")+theme_classic()
ggsave("plot_Surprise_byCond_hist.pdf", width = 7, height = 5)
dev.off()


ggplot(notes, aes(x=Surprise, color=cond, fill = cond)) +
  scale_color_manual(values=c("darkblue","red"))+facet_wrap(~type)+
  geom_density()+theme_classic()


table(notes$cond, notes$type)

wilcox.test(Surprise ~ cond, data = notes[notes$type == "Shuffled",])
wilcox.test(Surprise ~ cond, data = notes[notes$type == "Original",])
wilcox.test(So ~ type, data = notes[notes$cond == "S low",])

gg = with(notes, aggregate(cbind(Surprise, So, Sp) ~ cond+type+melID, FUN="mean"))  #get mean of STEP condition per block per subject
wilcox.test(Surprise ~ cond, data = gg[gg$type == "Shuffled",])
wilcox.test(Sp ~ type, data = gg[gg$cond == "S low",])
wilcox.test(Sp ~ type, data = gg[gg$cond == "S high",])


####TEST SHUFFLED VS ORIGINAL
m.1= lmer(P1~  type*Surprise +session+(1|monkey)+(1|melID),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)),
          data)
Anova(m.1, type=3)  #
emt=emtrends(m.1, pairwise ~ type, var = "Surprise")
summary(emt)
plot_model(m.1, type = "pred", terms = c("Surprise", "type"))
tab_model(m.1, file = "stats_P1ORvsSH.doc")
sjPlot::plot_model(m.1, show.values = TRUE, value.offset = .3)
ggsave(paste0("stat_P1ORvsSH.png"), width = 7, height = 5)


m.1= lmer(CNV~  type*Surprise +session+(1|monkey)+(1|melID),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)),
          data)
Anova(m.1, type=3)  #
emt2=emtrends(m.1, pairwise ~ type, var = "Surprise")
summary(emt2)
plot_model(m.1, type = "pred", terms = c("Surprise", "type"))
tab_model(m.1, file = "stats_P1ORvsSH.doc")
sjPlot::plot_model(m.1, show.values = TRUE, value.offset = .3)
ggsave(paste0("stat_P1ORvsSH.png"), width = 7, height = 5)


#### SURPRISE
data$session=as.numeric(data$session)
or = data %>% 
  group_by(monkey) %>% 
  filter(type == 'Original')

sh = data %>% 
  group_by(monkey) %>% 
  filter(type == 'Shuffled')
head(or)
unique(or$melID)

#SH vs OR (aggregate by session)
agg = with(or, aggregate(cbind(P1, IOI, ITI, Surprise, Sp, So) ~ monkey+melID+session+cond, FUN="mean"))  
ggplot(agg, aes(melID, Surprise, group=cond, fill = cond, color = cond))+
  theme_minimal()+facet_grid(~monkey)+
  stat_summary(fun=mean, geom="line")+
  stat_summary(fun=mean, geom="point")+
  scale_color_manual(values=c("darkblue","red"))+
  stat_summary( fun.data = 'mean_se', geom = "errorbar", width=0, alpha=0.6)+
  xlab("Piece") + ylab("Amplitude")+ggtitle('')
agg = with(sh, aggregate(cbind(P1, IOI, ITI, Surprise, Sp, So) ~ monkey+melID+session+cond, FUN="mean"))  
ggplot(agg, aes(melID, P1, group=cond, fill = cond, color = cond))+
  theme_minimal()+facet_grid(~monkey)+
  stat_summary(fun=mean, geom="line")+
  stat_summary(fun=mean, geom="point")+
  scale_color_manual(values=c("darkblue","red"))+
  stat_summary( fun.data = 'mean_se', geom = "errorbar", width=0, alpha=0.6)+
  xlab("Piece") + ylab("Amplitude")+ggtitle('')

m.1= lmer(P1~  Sp+ So+IOI + ITI +session +(1|monkey)+(1|melID),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)),
          or)
Anova(m.1, type=3)  #
plot_model(m.1, type = "pred", terms = c("So","IOI"))
tab_model(m.1, file = "stats_P1.doc")
sjPlot::plot_model(m.1, show.values = TRUE, value.offset = .3)
ggsave(paste0("stat_P1.png"), width = 7, height = 5)


########### EFFECT ON THE CNV? ONLY DRIVEN BY IOI both in original and shuffled

m.1= lmer(CNV  ~  Sp+ So+IOI + ITI +session +(1|monkey)+(1|melID),
          control = lmerControl(optimizer = 'bobyqa', optCtrl = list(maxfun = 10000)),
          or)
Anova(m.1, type=3)  
emt3=emtrends(m.1,  var = "IOI")
summary(emt3)



