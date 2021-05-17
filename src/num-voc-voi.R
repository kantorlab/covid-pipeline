library(tidyverse)

ri <- read_csv("results/qc-passed.csv")
cdc <- read_tsv("src/cdc-voc-voi.tsv")

ri <- left_join(ri, cdc, by="pangolin.lineage") %>%
      select(strain, date, pangolin.lineage, cdc.classification) %>%
      mutate(cdc.classification=replace_na(cdc.classification, "Non-VOC/Non-VOI"))

print(ri)

nseq <- nrow(ri)
earliest <- as.Date("2020-03-01")
latest <- max(ri$date)

ri <- group_by(ri, date, cdc.classification) %>%
  summarise(n=n()) %>%
  ungroup()

# Summarize by month
ri <- mutate(ri, month=lubridate::floor_date(date, unit="month")) %>%
  group_by(month, cdc.classification) %>%
  summarise(n=sum(n)) %>%
  ungroup()

print(ri)
print(sum(ri$n))

g <- ggplot(data=ri) +
geom_bar(aes(x=month, y=n, fill=cdc.classification), stat="identity") +
ggtitle("Monthly Number of RI SARS-CoV-2 Sequences") +
labs(
  x="Date of Sample",
  y="",
  fill="CDC Classification"
) +
scale_x_date(
  breaks=waiver(),
  date_breaks="month",
  labels=waiver(),
  date_labels="%b %Y"
) +
scale_y_continuous(position="right") +
scale_fill_manual(
  values=c(
    "Non-VOC/Non-VOI"="darkgray",
    "VOI"="#ff7f00",
    "VOC"="#e41a1c"
  )
) +
guides(colour=guide_legend(nrow=1)) +
theme_classic() +
theme(
  title=element_text(size=9),
  plot.title=element_text(size=10, hjust=0.5),
  plot.title.position="panel",
  legend.position="top",
  legend.direction="horizontal",
  legend.title=element_text(size=9),
  legend.text=element_text(size=8),
  legend.text.align=0,
  legend.justification="center",
  legend.key.size=unit(0.1, "in"),
  axis.line=element_blank(),
  axis.ticks.x=element_line(size=0.25),
  axis.ticks.y=element_blank(),
  axis.text.x=element_text(size=8, color="black", angle=90, hjust=1, vjust=0.5),
  axis.text.y=element_text(size=8, color="black"),
  panel.grid.major.y=element_line(color="gray", size=0.1)
)

pdf(file="results/num-voc-voi.pdf", width=4, height=4)
print(g)
dev.off()

ri <- pivot_wider(ri, names_from=cdc.classification, values_from=n) %>%
  replace(is.na(.), 0)

write_csv(ri, "results/num-voc-voi.csv")

