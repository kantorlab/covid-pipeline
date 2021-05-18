library(tidyverse)

ri <- read_csv("results/qc-passed.csv") %>%
      select(strain, date, pangolin.lineage, cdc.classification) %>%
      arrange(date)

muts <- read_csv("results/concern-long.csv") %>%
        select(sample, mutation) %>%
        rename(strain=sample) %>%
        mutate(value=1) %>%
        pivot_wider(names_from=mutation, values_from=value)
print(muts)

ri <- left_join(ri, muts, by="strain") %>%
      mutate(step=1,
             voc=as.factor(case_when(cdc.classification == "VOC" ~ "VOC/VOI",
                                     cdc.classification == "VOI" ~ "VOC/VOI",
                                     `S:E484K` == 1  & `S:D614G` == 1 ~ "Non-VOC/Non-VOI with E484K and D614G",
                                     `S:E484K` == 1 ~ "Non-VOC/Non-VOI with E484K",
                                     `S:D614G` == 1 ~ "Non-VOC/Non-VOI with D614G",
                                     TRUE                          ~ "Other")))

nseq <- nrow(ri)
nnon <- sum(ri$voc != "VOC/VOI")
earliest <- min(ri$date)
latest <- max(ri$date)

ri <- group_by(ri, date, voc) %>%
  summarise(step=sum(step)) %>%
  ungroup() %>%
  group_by(voc) %>%
  mutate(Cumulative=cumsum(step)) %>%
  ungroup()

# Summarize by week
ri <- mutate(ri, week=lubridate::floor_date(date, unit="week")) %>%
  group_by(week, voc) %>%
  summarise(Cumulative=max(Cumulative)) %>%
  ungroup() %>%
  pivot_wider(names_from=voc, values_from=Cumulative)

print(ri)

ri <- tibble(week=seq.Date(from=lubridate::floor_date(earliest, unit="week"), to=lubridate::floor_date(latest, unit="week"), by="week")) %>% 
  left_join(ri, on="week") %>%
  fill(everything()) %>%
  replace(is.na(.), 0)

print(ri)

write_csv(ri, "results/non-voc-voi-mutations.csv")

ri <- ri %>%
  pivot_longer(!week, names_to="voc", values_to="Cumulative") %>%
  mutate(voc=factor(voc, levels=c(
    "VOC/VOI",
    "Non-VOC/Non-VOI with E484K and D614G",
    "Non-VOC/Non-VOI with E484K",
    "Non-VOC/Non-VOI with D614G",
    "Other"
  )))
print(ri)

g <- ggplot(data=ri) +
geom_area(aes(x=week, y=Cumulative, fill=voc)) +
geom_hline(yintercept=nseq, linetype="dashed", color="black", size=0.25) +
geom_text(
  data=data.frame(x=earliest, y=c(1.02*nseq), label=c(paste(scales::comma(nseq), "RI SARS-CoV-2 sequences as of", strftime(latest, format="%B %-m, %Y")))),
  aes(x=x, y=y, label=label, vjust=0, hjust=0),
  size=2.5
) +
geom_hline(yintercept=nnon, linetype="dashed", color="black", size=0.25) +
geom_text(
  data=data.frame(x=earliest, y=c(1.02*nnon), label=c(paste(scales::comma(nnon), "non-COV/non-COI sequences"))),
  aes(x=x, y=y, label=label, vjust=0, hjust=0),
  size=2.5
) +
labs(
  x="Date of Sample",
  y="Cumulative Number of Sequences",
  fill="CDC Classification"
) +
scale_x_date(
  breaks=waiver(),
  date_breaks="month",
  labels=waiver(),
  date_labels="%b %Y"
) +
scale_y_continuous(breaks=seq(0, 3000, 500), position="right") +
scale_fill_manual(
  values=c(
    "VOC/VOI"="darkgray",
    "Non-VOC/Non-VOI with E484K and D614G"="#f46d43",
    "Non-VOC/Non-VOI with E484K"="#fdae61",
    "Non-VOC/Non-VOI with D614G"="#fee090",
    "Other"="gray"
  )
) +
theme_classic() +
theme(
  title=element_text(size=9),
  legend.position=c(0, 0.35),
  legend.justification=c("left", "center"),
  legend.title=element_text(size=9),
  legend.text=element_text(size=8),
  legend.key.size=unit(0.1, "in"),
  legend.background=element_blank(),
  axis.line=element_blank(),
  axis.ticks.x=element_line(size=0.25),
  axis.ticks.y=element_blank(),
  axis.text.x=element_text(size=8, color="black", angle=90, hjust=1, vjust=0.5),
  axis.text.y=element_text(size=8, color="black"),
  panel.grid.major.y=element_line(color="gray", size=0.1)
)

pdf(file="results/non-voc-voi-mutations.pdf", width=4, height=3.5)
print(g)
dev.off()

