library(ggplot2)
library(car)
library(sjPlot)
library(tidyverse)
library(ggpubr)
library(rstatix)
library(broom)
library(Hmisc)


ls()
rm(list=ls())
getwd( )
setwd("../../data/eeg/TRF_MEMORY/")

#################LOAD MK DATA
data = read.csv( "PredAccTRFforstat_MONKEY.csv", header = F, sep = ',') 
colnames(data) <- c("sub", "PredAcc","condition", "model", "melID", "ngram") 
data$condition = as.factor(data$condition)
data$model = as.factor(data$model)
data$melID= as.factor(data$melID)
data$condition = fct_recode(data$condition, "Original" = "1")
data$model = fct_recode(data$model, "AM-A" = "1", "AMp-A" = "2", "AMo-A" = '3')
data$melID = fct_recode(data$melID, "o_05"= "5", "o_08"= "8", "o_03"= "3", "o_06"= "6", "o_04"= "4",
                        "o_09"= "9", "o_02"= "2", "o_01"= "1", "o_07"= "7", "o_10"= "10")
data$ngramnum = data$ngram
data$ngram = as.factor(data$ngram)
data$ngram = fct_recode(data$ngram, "1"= "1", "2"= "2", "3"= "3", "4"= "4", "8"= "5",
                        "12"= "6", "16"= "7", "20"= "8", "24"= "9", "inf"= "10")
summary(data)
datamk = data

############LOAD HUMAN DATA 
data = read.csv("PredAccTRFforstat_HUMAN.csv", header = F, sep = ',') 
colnames(data) <- c("sub", "PredAcc","condition", "model", "melID", "ngram") 
data$condition = as.factor(data$condition)
data$model = as.factor(data$model)
data$melID= as.factor(data$melID)
data$condition = fct_recode(data$condition, "Original" = "1")
data$model = fct_recode(data$model, "AM-A" = "1", "AMp-A" = "2", "AMo-A" = '3')
data$melID = fct_recode(data$melID, "o_05"= "5", "o_08"= "8", "o_03"= "3", "o_06"= "6", "o_04"= "4",
                        "o_09"= "9", "o_02"= "2", "o_01"= "1", "o_07"= "7", "o_10"= "10")
data$ngramnum = data$ngram
data$ngram=as.factor(data$ngram)
data$ngram = fct_recode(data$ngram, "1"= "1", "2"= "2", "3"= "3", "4"= "4", "8"= "5",
                        "12"= "6", "16"= "7", "20"= "8", "24"= "9", "inf"= "10")

summary(data)
datahm = data

datamk$specie = 'mk'
datahm$specie = 'hm'
data = rbind(datamk, datahm)
data$specie=as.factor(data$specie)
data = droplevels(data[data$ngram!='inf',])
data = droplevels(data[data$model != "AM-A", ])
data$sub = paste0(data$sub, '_', data$specie)

data = data %>%
  group_by(sub) %>%
  mutate(PredAccz = (PredAcc - mean(PredAcc, na.rm=T))/sd(PredAcc, na.rm=T))


library(RColorBrewer)
darkcols <- brewer.pal(8, "Dark2")

ag=with(data, aggregate(cbind(PredAccz, PredAcc) ~model+ngram+specie+sub, FUN="mean")) #aggregate by melody
ggplot(ag, aes(ngram, PredAcc, group = model, color = model))+  
  theme_classic()+
  #stat_summary( fun.data = 'mean_cl_boot', geom = "errorbar", width = 0, alpha=0.6)+
  stat_summary(fun=mean, geom="line")+
  stat_summary(fun=mean, geom="point")+
  facet_wrap(~ specie, scales="free_y")+
  theme_classic()+xlab("n-gram") + ylab("Delta Pred. Acc. (r)")+
  scale_color_manual(values=c(darkcols[6], darkcols[1]))+
  scale_fill_manual(values=c(darkcols[6], darkcols[1]))+
  ggtitle('')+theme(legend.position = 'bottom')
ggsave("plot_ngrammodels_bothspecie.pdf", width = 5,height = 4)
ggsave("plot_ngrammodels_bothspecie.png", width = 5, height = 4)

ag=with(data[data$specie=='hm' & data$model=='AMo-A',], aggregate(cbind(PredAccz, PredAcc) ~model+ngram, FUN="mean")) #aggregate by melody
ag[ag$PredAcc==max(ag$PredAcc),]
ag=with(data[data$specie=='mk'  & data$model=='AMo-A',], aggregate(cbind(PredAccz, PredAcc) ~model+ngram, FUN="mean")) #aggregate by melody
ag[ag$PredAcc==max(ag$PredAcc),]


