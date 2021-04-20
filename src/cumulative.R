library(tidyverse)

all <- read_tsv("ri_metadata.tsv")
print(nrow(all))

ri <- filter(all, division=="Rhode Island") %>%
  mutate(
    step=1,
    Source=as.factor(case_when(
      startsWith(strain, "hCoV-19/USA/RI-Broad") ~ "Broad",
      startsWith(strain, "hCoV-19/USA/RI-CDC")   ~ "CDC",
      startsWith(strain, "RI_")                  ~ "Kantor Lab",
      TRUE                                       ~ "Other"))
  ) %>%
  arrange(date) %>%
  mutate(Cumulative=cumsum(step)) %>%
  group_by(Source) %>%
  mutate(CumulativeByGroup=cumsum(step))
print(nrow(ri))
print(ri)
print(select(filter(ri, Source=="Other"), strain), n=100)

pdf(file="results/cumulative.pdf", width=9, height=6.5)
ggplot(data=ri) +
geom_step(aes(x=date, y=Cumulative)) +
geom_step(aes(x=date, y=CumulativeByGroup, group=Source, color=Source)) +
labs(
  x="Date of Sample",
  y="# Cumulative Sequences"
)
dev.off()

pdf(file="results/cumulative-all.pdf", width=9, height=6.5)
ggplot(data=ri) +
geom_step(aes(x=date, y=Cumulative)) +
labs(
  x="Date of Sample",
  y="# Cumulative Sequences"
)
dev.off()
