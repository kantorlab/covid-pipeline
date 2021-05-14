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

ri_all <- group_by(ri, date) %>%
  summarise(step=sum(step)) %>%
  ungroup() %>%
  mutate(Cumulative=cumsum(step), Source="All")
print(ri_all)

ri_lab <- group_by(ri, date, Source) %>%
  summarise(step=sum(step)) %>%
  ungroup() %>%
  group_by(Source) %>%
  mutate(Cumulative=cumsum(step)) %>%
  ungroup()
print(ri_lab)

# Recombine into one frame
ri <- bind_rows(ri_all, ri_lab)

# Extend lines to the right
earliest <- min(ri$date)
latest <- max(ri$date)
ri <- bind_rows(ri,
    arrange(ri, desc(date)) %>%
    distinct(Source, .keep_all=TRUE) %>%
    mutate(date=latest)
  ) %>%
  distinct() %>%
  mutate(Source=factor(Source, levels=c("All", "CDC", "Broad", "Kantor Lab", "RISHL", "Other")))

write_csv(ri, "results/cumulative.csv")

nseq <- max(ri$Cumulative)

g <- ggplot(data=ri) +
geom_step(aes(x=date, y=Cumulative, group=Source, color=Source), size=0.25) +
geom_hline(yintercept=nseq, linetype="dashed", color="black", size=0.25) +
geom_text(
  data=data.frame(x=c(earliest), y=c(1.02*nseq), label=c(paste(scales::comma(nseq), "sequences as of", strftime(latest, format="%B %-m, %Y")))),
  aes(x=x, y=y, label=label, vjust=0, hjust=0),
  size=2.5
) +
ggtitle("Rhode Island SARS-CoV-2 Sequences by Source") +
labs(
  x="Date of Sample",
  y="# Cumulative Sequences"
) +
scale_x_date(
  limits=c(earliest, latest),
  breaks=waiver(),
  date_breaks="month",
  labels=waiver(),
  date_labels="%b %Y"
) +
scale_y_continuous(breaks=seq(0, 3000, 500), position="right") +
scale_colour_manual(
  values=c(
    "All"="black",
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
  plot.title=element_text(size=10),
  legend.position="top",
  legend.direction="horizontal",
  legend.title=element_blank(),
  legend.margin=margin(l=0.1, unit="in"),
  legend.text=element_text(size=8),
  legend.text.align=0,
  legend.justification=0,
  legend.key.size=unit(0.15, "in"),
  axis.line=element_blank(),
  axis.ticks.x=element_line(size=0.25),
  axis.ticks.y=element_blank(),
  axis.text.x=element_text(size=8, color="black", angle=90, hjust=1, vjust=0.5),
  axis.text.y=element_text(size=8, color="black"),
  panel.grid.major.y=element_line(color="gray", size=0.1)
)

pdf(file="results/cumulative.pdf", width=4, height=4)
print(g)
dev.off()

