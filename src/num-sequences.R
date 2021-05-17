library(tidyverse)

ri <- read_csv("results/qc-passed.csv") %>%
  mutate(
    step=1,
    Source=as.factor(case_when(
      startsWith(strain, "hCoV-19/USA/RI-Broad") ~ "Broad",
      startsWith(strain, "hCoV-19/USA/RI-CDC")   ~ "CDC",
      startsWith(strain, "hCoV-19/USA/RI-RISHL") ~ "RISHL",
      startsWith(strain, "hCoV-19/USA/RI_RKL")   ~ "Kantor Lab",
      TRUE                                       ~ "Other"))
  ) %>%
  arrange(date)
print(select(filter(ri, Source=="Other"), strain), n=100)

nseq <- nrow(ri)
earliest <- min(ri$date)
latest <- max(ri$date)

ri <- group_by(ri, date, Source) %>%
  summarise(step=sum(step)) %>%
  ungroup() %>%
  group_by(Source) %>%
  mutate(Cumulative=cumsum(step)) %>%
  ungroup()

write_csv(ri, "results/num-sequences.csv")

# Summarize by week
ri <- mutate(ri, week=lubridate::floor_date(date, unit="week")) %>%
  group_by(week, Source) %>%
  summarise(Cumulative=max(Cumulative)) %>%
  ungroup() %>%
  pivot_wider(names_from=Source, values_from=Cumulative)

print(ri)

ri <- tibble(week=seq.Date(from=lubridate::floor_date(earliest, unit="week"), to=lubridate::floor_date(latest, unit="week"), by="week")) %>% 
  left_join(ri, on="week") %>%
  fill(everything()) %>%
  replace(is.na(.), 0)

print(ri)

ri <- ri %>%
  pivot_longer(!week, names_to="Source", values_to="Cumulative") %>%
  mutate(Source=factor(Source, levels=c("CDC", "Broad", "Kantor Lab", "RISHL", "Other")))

print(ri)

g <- ggplot(data=ri) +
geom_area(aes(x=week, y=Cumulative, fill=Source)) +
geom_hline(yintercept=nseq, linetype="dashed", color="black", size=0.25) +
geom_text(
  data=data.frame(x=earliest, y=c(1.02*nseq), label=c(paste(scales::comma(nseq), "sequences as of", strftime(latest, format="%B %-m, %Y")))),
  aes(x=x, y=y, label=label, vjust=0, hjust=0),
  size=2.5
) +
ggtitle("Cumulative Number of RI SARS-CoV-2 Sequences") +
labs(
  x="Date of Sample",
  y=""
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
    "CDC"="#e41a1c",
    "Broad"="#377eb8",
    "Kantor Lab"="#4daf4a",
    "RISHL"="#984ea3",
    "Other"="darkgray"
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

pdf(file="results/num-sequences.pdf", width=4, height=4)
print(g)
dev.off()

