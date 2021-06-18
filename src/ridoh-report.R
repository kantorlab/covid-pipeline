library(tidyverse)
library(stringr)
library(stringi)
library(readxl)

ref_len <- 29903

data <- read_csv("results/qc-passed.csv") %>%
  mutate(seqName=strain,
	 pango_lineage=pangolin.lineage,
         nextclade_clade=nextclade.clade,
         geo_loc_name="USA: Rhode Island",
         collection_date=date,
	 totalMutations=nextclade.totalMutations,
         sequence_length=seq_len,
         percent_genome_coverage=round(seq_len/ref_len*100,1),
         nextclade_aa_substitutions=nextclade.aaSubstitutions,
         nextclade_aa_deletions=nextclade.aaDeletions,
         purpose_of_sequencing="Screening for Variants of Concern (VoC)",
         comment="") %>%
  select(seqName,pango_lineage,nextclade_clade,collection_date,
         totalMutations,sequence_length,percent_genome_coverage,
         nextclade_aa_substitutions,nextclade_aa_deletions,purpose_of_sequencing,
         comment)

f_out <- paste0("results/n",nrow(data),"_RI_per_sample_nextclade_oscar_",format(Sys.Date(),"%Y%b%d"), ".xlsx")
openxlsx::write.xlsx(data, file = f_out)

