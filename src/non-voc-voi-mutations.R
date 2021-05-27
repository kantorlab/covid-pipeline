library(tidyverse)

ri <- read_csv("results/concern-long.csv")

mutations <- ri %>% group_by(mutation) %>% tally() %>% arrange(-n)
print(mutations)

top5 <- head(mutations$mutation, 5)
print(top5)

colors <- c(
  "#e41a1c",
  "#377eb8",
  "#4daf4a",
  "#984ea3",
  "#ff7f00",
  "darkgray"
)
names(colors) <- c(top5, "Other")
print(colors)

ri <- mutate(ri,
             step=1,
             voc=case_when(mutation %in% top5 ~ mutation,
                           TRUE               ~ "Other"))

nseq <- nrow(ri)
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
  pivot_longer(!week, names_to="voc", values_to="Cumulative") %>% mutate(voc=factor(voc, levels=c(top5, "Other")))
print(ri)

g <- ggplot(data=ri) +
geom_bar(aes(x=week, y=Cumulative, fill=voc), stat="identity") +
labs(
  x="Date of Sample",
  y="Cumulative Number of Mutations",
  fill="Mutation"
) +
scale_x_date(
  breaks=waiver(),
  date_breaks="month",
  labels=waiver(),
  date_labels="%b %Y"
) +
scale_fill_manual(values=colors) +
theme_classic() +
theme(
  title=element_text(size=9),
  legend.position="top",
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

win.metafile(file="results/non-voc-voi-mutations.wmf", width=4, height=3.5)
print(g)
dev.off()
