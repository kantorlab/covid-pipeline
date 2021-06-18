library(tidyverse)
library(scales)
library(lubridate)
library(readxl)
library(RColorBrewer)

##### Extract dates and enumerate variants of concern from pangolin results

### date format: x1 <- stamp("Mar 2, 2020")(ymd("2021-04-25")) # Apr 25, 2021

var_of_concern <- c("B.1.1.7","B.1.351","P.1","B.1.427","B.1.429","B.1.525",
                    "B.1.526","B.1.526.1","P.2","B.1.617","B.1.617.1","B.1.617.2","B.1.617.3")
# manual colors:
set1mod14 <- c("#FF3300","#6600CC","#CC0066","#CC9900","#FF9900","#0000FF","#3399FF","#00CCFF",
               "#FF99FF","#006633","#009900","#00CC33","#33FF99","#989898")

var_regions <- c("UK","South Africa","Brazil","California, USA","California, USA","New York, USA",
                 "New York, USA","New York, USA","Brazil","India","India","India","India")

# Pangolin QC only (without nextstrain QC)
# pangolin results from Oscar
pangolin_res <- read_csv("results/qc-passed.csv") %>%
  rename(seqName=strain, lineage=pangolin.lineage, coll_date=date) %>%
  select(seqName, lineage, coll_date)
                           
# combine B.1.526 with B.1.526.2
sum_df <- pangolin_res %>%
  mutate(lineage = if_else((lineage == "B.1.526.2" | lineage == "B.1.526.3"),"B.1.526",lineage))

roundUp <- function(x) 10^ceiling(log10(x))

dat1 <- sum_df

var_concern_df <- as.data.frame(matrix(NA,0,6))

for(z in 1:length(var_of_concern)){
  loc_variant <- dat1 %>%
    filter(lineage == var_of_concern[z]) %>%
    group_by(coll_date) %>%
    summarise(n=n()) %>%
    arrange(coll_date) 
  
  if(nrow(loc_variant) > 0){
    loc_df <- as.data.frame(matrix(NA,nrow(loc_variant),6))
    loc_df$V1 <- var_of_concern[z]
    loc_df$V2 <- var_regions[z]
    loc_df$V3[1] <- sum(loc_variant$n)
    loc_df$V4 <- loc_variant$coll_date
    if(nrow(loc_variant) > 1){
      loc_df$V5 <- paste(stamp("Mar 2")(ymd(loc_variant$coll_date[1])),"to", stamp("Mar 2, 2020")(ymd(loc_variant$coll_date[nrow(loc_variant)])))
    } else {
      loc_df$V5 <- paste0(" ", stamp("Mar 2, 2020")(ymd(loc_variant$coll_date[1])))
    }
    loc_df$V6 <- loc_variant$n
  } else {
    loc_df <- as.data.frame(matrix(NA,1,5))
    loc_df$V1[1] <- var_of_concern[z]
    loc_df$V2 <- var_regions[z]
    loc_df$V3[1] <- 0
    loc_df$V4[1] <- NA
    loc_df$V5[1] <- "-"
    loc_df$V6[1] <- NA
  }
  var_concern_df <- rbind(var_concern_df,loc_df)
}

colnames(var_concern_df) <- c("variant","region","total","coll_date","date_range","n_per_date")
var_concern_df$variant <- factor(var_concern_df$variant, level=unique(var_concern_df$variant))

# number total with date range
report_total <- var_concern_df %>%
  filter(!is.na(total)) %>%
  select(variant,region,total,date_range)
colnames(report_total) <- c("Variant of concern/interest","Region Variant was Originally Identified","Identified total cases, n","Range of sampling dates")

f_var_total_out <- paste0("results/variants_of_concern_summary_oscar_",format(Sys.Date(),"%Y%b%d"),".xlsx")
openxlsx::write.xlsx(report_total,f_var_total_out)

####
# numbers per variant per week
rep_by_week <- var_concern_df %>%
  mutate(week = week(coll_date)) %>%
  group_by(variant,week) %>%
  summarise(n=sum(n_per_date)) %>%
  filter(!is.na(n))

rep_by_week$n <- as.numeric(rep_by_week$n)


### sequences by date

dat2 <- dat1 %>%
  mutate(Source = if_else(str_detect(seqName,"_RKL_"),"Kantor Lab",
                          if_else(str_detect(seqName,"RISHL"),"RISHL",
                                  if_else((str_detect(seqName,"Broad") | str_detect(seqName,"CDCBI")),"Broad",
                                          if_else(str_detect(seqName,"CDC-"),"CDC","Others")))),
         value = sample(1:nrow(dat1)))

total_num <- round(nrow(dat2)+50,-2)
minor_breaks <- roundUp(total_num/10)/5

### Total
dat3 <- dat2 %>%  # total cumulative
  group_by(coll_date) %>%
  summarize(n=n()) %>%
  mutate(N=cumsum(n),Source="Total") %>%
  select(Source,coll_date,N)

dat4 <- dat2 %>%   # by source cumulative
  group_by(Source,coll_date) %>%
  summarize(n=n()) %>%
  mutate(N=cumsum(n)) %>%
  select(-n)

dat5 <- full_join(dat3,dat4)

dat5$Source <- factor(dat5$Source,levels = c("Broad","CDC","Kantor Lab","RISHL","Others","Total"))

#
starting_date <- "2020-12-01"

for(i in 1:length(unique(dat5$Source))){
  loc_df <- dat5 %>%
    filter(Source == unique(dat5$Source)[i])
  source_with_starting_date <- loc_df %>%
    filter(coll_date == starting_date)
  if(nrow(source_with_starting_date) >= 1){
    next
  } else {
    loc_df_before <- loc_df %>%
      filter(coll_date < starting_date)
    if(nrow(loc_df_before) > 0){
      starting_number <- loc_df_before$N[nrow(loc_df_before)]
      new_line <- cbind(as.character(unique(dat5$Source)[i]),starting_date,starting_number)
      colnames(new_line) <- c("Source","coll_date","N")
      dat5 <- rbind(dat5,new_line)
      
    }
  }
}


dat6 <- dat5 %>%
  arrange(Source,coll_date) %>%
  filter(coll_date >= starting_date)
dat6$N <- as.numeric(dat6$N)

# Figure 1
ggplot(dat6,aes(x=coll_date,y=N,group=Source)) +
  geom_line(aes(col=Source),size=1.2) +
  scale_color_manual(values=c("#0095d6","#19b24b","#FF9900","#05618a","#d6bc00","#d60f63")) + # AI panel High Contrast 2
  scale_x_date(breaks=date_breaks("1 months"),labels=date_format("%b %y")) +
  scale_y_continuous(name="Cumulative Sequences, n", breaks=seq(0,total_num,minor_breaks)) +
  xlab("Date of Sample") +
  theme_classic() +
  theme(axis.text= element_text(size=18),
        axis.text.x = element_text(size = 14, angle = 90,hjust = 1, vjust = 0.5),
        axis.title = element_text(size = 18),
        legend.title = element_text(size=16),
        legend.text = element_text(size = 15))

f_out <- paste("results/Fig-1B_n",nrow(dat1),"_cumulative_seqs_",format(Sys.Date(),"%Y%b%d"),".pdf",sep = "")
ggsave(f_out, device = "pdf",width = 10, height = 10, dpi = 300)


#### graphs with variants of concern and variants of interest

f2_in <- read_csv("src/weeks_2021.csv")
incl_weeks <- f2_in$Date

total_per_week_tmp <- dat1 %>%
  filter(year(coll_date) >= 2021) %>%
  mutate(week = week(coll_date)) %>%
  group_by(week) %>%
  summarise(n=n())

last_week <- total_per_week_tmp$week[nrow(total_per_week_tmp)]
week <- c(1:last_week)
weeks_df <- data.frame(week)
total_per_week <- left_join(weeks_df,total_per_week_tmp,by="week")
total_per_week$n[is.na(total_per_week$n)] <- 0

total_per_week$variant <- "Total"
total_per_week$date_range <- NA
for(k in 1:nrow(total_per_week)){
  total_df <- f2_in %>%
    filter(MMWR_week == total_per_week$week[k])
  total_per_week$date_range[k] <- total_df$Date[1]
}
total_per_week$date_range <- factor(total_per_week$date_range, levels = f2_in$Date)


# create a data frame with existing variants using total_per_week as a base
var_per_week <- as.data.frame(matrix(NA,0,4))
for(i in 1:length(var_of_concern)){
  local_df <- rep_by_week %>%
    filter(variant == var_of_concern[i])
  loc_df_per_var <- as.data.frame(matrix(NA,nrow(total_per_week),4))
  loc_df_per_var$V1 <- var_of_concern[i]
  loc_df_per_var$V2 <- total_per_week$week
  loc_df_per_var$V4 <- total_per_week$date_range
  if(nrow(local_df) > 0){
    for(m in 1:nrow(total_per_week)){
      for(l in 1:nrow(local_df)){
        if(local_df$week[l] == m){
          loc_df_per_var$V3[m] <- local_df$n[l]
          break
        } else {
          loc_df_per_var$V3[m] <- 0
        }
      }
    }
  } else {
    loc_df_per_var$V3 <- 0
  }
  var_per_week <- rbind(var_per_week,loc_df_per_var)
}
colnames(var_per_week) <- c("variant","week","n","date_range")


# Figure 2: stacked bars with % of VOC, VOI and non-VOC/non-VOI 
var_per_week$perc <- NA
percent_var_per_week <- as.data.frame(matrix(NA,0,5))
for(i in 1:nrow(total_per_week)){
  loc_df_perc <- var_per_week %>%
    filter(week == i)
  variant <- "non-VOC/non-VOI"
  week <- i
  n <- total_per_week$n[i] - sum(loc_df_perc$n)
  date_range <- as.character(total_per_week$date_range[i])
  perc <- round(n/total_per_week$n[i]*100,1)
  non_voc_voi <- cbind(variant,week,n,date_range,perc)
  for(k in 1:nrow(loc_df_perc)){
    loc_df_perc$perc[k] <- round(loc_df_perc$n[k]/total_per_week$n[i]*100,1)
  }
  loc_df_perc <- rbind(loc_df_perc,non_voc_voi)
  percent_var_per_week <- rbind(percent_var_per_week,loc_df_perc)
}

percent_var_per_week$perc <- as.numeric(percent_var_per_week$perc)
percent_var_per_week$n <- as.numeric(percent_var_per_week$n)
percent_var_per_week$variant <- factor(percent_var_per_week$variant, level=unique(percent_var_per_week$variant))

# stacked bars with %
ggplot(percent_var_per_week) + 
  geom_bar(aes(x = date_range, y = perc, fill = variant),color="white",stat = "identity") +
  scale_fill_manual(values = set1mod14) +
  scale_x_discrete(labels = incl_weeks) +
  geom_text(data=total_per_week,aes(x = date_range, y = 100, label=n), size = 8, vjust = -0.5) +
  xlab("Collection date, weeks during 2021") +
  ylab("Percent of identified cases, %") +
  theme_classic() +
  theme(axis.text= element_text(size=18),
        axis.text.x = element_text(angle=45, vjust=1, hjust = 1, size=16),
        axis.title = element_text(size = 18),
        legend.title = element_blank(),
        legend.text = element_text(size = 25),
        legend.position="top")

f_out <- paste("results/Fig-2_set1mod14_Lineges_of_concern_in_RI_by_week_",format(Sys.Date(),"%Y%b%d"),".pdf",sep = "")
ggsave(f_out, device = "pdf",width = 12, height = 10, dpi = 300)

# Figure 3: stacked bars with actual numbers
ggplot(percent_var_per_week) + 
  geom_bar(aes(x = date_range, y = n, fill = variant),color="white",stat = "identity") +
  scale_fill_manual(values = set1mod14) +
  scale_x_discrete(labels = incl_weeks) +
  xlab("Collection date, weeks during 2021") +
  ylab("Identified cases, n") +
  theme_classic() +
  theme(axis.text= element_text(size=18),
        axis.text.x = element_text(angle=45, vjust=1, hjust = 1, size=16),
        axis.title = element_text(size = 22),
        legend.title = element_blank(),
        legend.text = element_text(size = 25),
        legend.position="top")

f_out <- paste("results/Fig-3_set1mo14_Lineges_of_concern_in_RI_by_week_",format(Sys.Date(),"%Y%b%d"),".pdf",sep = "")
ggsave(f_out, device = "pdf",width = 12, height = 10, dpi = 300)

# Figure 4: stacked bars with actual number but without non-VOC/non-VOI
df_var_per_week <- percent_var_per_week %>%
  filter(variant != "non-VOC/non-VOI") %>%
  select(-perc)

tmp_df <- df_var_per_week %>%
  group_by(week) %>%
  summarise(m_n=sum(n))

max_y <- round(max(tmp_df$m_n)+10,-1)
minor_br_y <- roundUp(max_y/10)/5
  
ggplot(df_var_per_week) + 
  geom_bar(aes(x = date_range, y = n, fill = variant),color="white",stat = "identity") +
  scale_fill_manual(values = set1mod14) +
  scale_x_discrete(labels = incl_weeks) +
  scale_y_continuous(name="Identified cases, n", breaks=seq(0,max_y,minor_br_y)) +
  xlab("Collection date, weeks during 2021") +
  theme_classic() +
  theme(axis.text= element_text(size=18),
        axis.text.x = element_text(angle=45, vjust=1, hjust = 1, size=16),
        axis.title = element_text(size = 22),
        legend.title = element_blank(),
        legend.text = element_text(size = 25),
        legend.position="top")

f_out <- paste("results/Fig-4_set1mod14_VOC-VOI_in_RI_by_week_",format(Sys.Date(),"%Y%b%d"),".pdf",sep = "")
ggsave(f_out, device = "pdf",width = 12, height = 10, dpi = 300)

