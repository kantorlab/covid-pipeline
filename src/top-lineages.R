library(tidyverse)

ri <- read_csv("results/qc-passed.csv")

top <- group_by(ri, pangolin.lineage) %>% tally() %>% arrange(n) %>% tail(5)
print(top)

cdc <- read_tsv("src/cdc-voc-voi.tsv")
ri <- left_join(ri, cdc, by="pangolin.lineage") %>%
      select(date, pangolin.lineage, cdc.classification) %>%
      arrange(date)
print(ri)

ri <- mutate(ri,
	     step=1,
	     voc=as.factor(case_when(pangolin.lineage == "B.1.1.7" ~ "B.1.1.7 (VOC)",
				     pangolin.lineage == "B.1.526" ~ "B.1.526 (VOI) / B.1.526.1 (VOI) / B.1.526.2",
				     pangolin.lineage == "B.1.526.1" ~ "B.1.526 (VOI) / B.1.526.1 (VOI) / B.1.526.2",
				     pangolin.lineage == "B.1.526.2" ~ "B.1.526 (VOI) / B.1.526.1 (VOI) / B.1.526.2",
				     pangolin.lineage == "B.1"   ~ "B.1",
				     pangolin.lineage == "B.1.2"   ~ "B.1.2",
				     pangolin.lineage == "B.1.375" ~ "B.1.375",
				     TRUE                          ~ "Other")))

nseq <- nrow(ri)
earliest <- min(ri$date)
latest <- max(ri$date)

ri <- group_by(ri, date, voc) %>%
  summarise(step=sum(step)) %>%
  ungroup() %>%
  group_by(voc) %>%
  mutate(Cumulative=cumsum(step)) %>%
  ungroup()

write_csv(ri, "results/top-lineages.csv")

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

ri <- ri %>%
  pivot_longer(!week, names_to="voc", values_to="Cumulative") %>%
  mutate(voc=factor(voc, levels=c("B.1.1.7 (VOC)", "B.1.526 (VOI) / B.1.526.1 (VOI) / B.1.526.2", "B.1.2", "B.1.375", "B.1", "Other")))

print(ri)

g <- ggplot(data=ri) +
geom_area(aes(x=week, y=Cumulative, fill=voc)) +
geom_hline(yintercept=nseq, linetype="dashed", color="black", size=0.25) +
geom_text(
  data=data.frame(x=earliest, y=c(1.02*nseq), label=c(paste(scales::comma(nseq), "RI SARS-CoV-2 sequences as of", strftime(latest, format="%B %-m, %Y")))),
  aes(x=x, y=y, label=label, vjust=0, hjust=0),
  size=2.5
) +
labs(
  x="Date of Sample",
  y="Cumulative Number of Sequences",
  fill="Lineage"
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
    "B.1.1.7 (VOC)"="#e41a1c",
    "B.1.526 (VOI) / B.1.526.1 (VOI) / B.1.526.2"="#ff7f00",
    "B.1.2"="#abd9e9",
    "B.1.375"="#74add1",
    "B.1"="#4575b4",
    "Other"="gray"
  )
) +
theme_classic() +
theme(
  title=element_text(size=9),
  legend.position=c(0, 0.5),
  legend.justification=c("left", "center"),
  legend.title=element_text(size=9),
  legend.text=element_text(size=8),
  legend.key.size=unit(0.1, "in"),
  axis.line=element_blank(),
  axis.ticks.x=element_line(size=0.25),
  axis.ticks.y=element_blank(),
  axis.text.x=element_text(size=8, color="black", angle=90, hjust=1, vjust=0.5),
  axis.text.y=element_text(size=8, color="black"),
  panel.grid.major.y=element_line(color="gray", size=0.1)
)

pdf(file="results/top-lineages.pdf", width=4, height=3.5)
print(g)
dev.off()

