#!/bin/bash
#SBATCH -c 1
#SBATCH --mem=8G
#SBATCH -t 12:00:00

set -e
CONDA=/gpfs/data/rkantor/conda/bin
BIN=/gpfs/data/rkantor/bin
source $CONDA/activate covid-v1

mkdir -p results

# Run pangolin
pip install --upgrade git+https://github.com/cov-lineages/pangolin.git
pip install --upgrade git+https://github.com/cov-lineages/pangoLEARN.git
pangolin ri_sequences.fa -o results/pangolin --alignment --no-temp

# Run nextclade
nextclade \
	--input-fasta ri_sequences.fa \
	--output-json 'results/nextclade.json' \
	--output-csv 'results/nextclade.csv' \
	--output-tsv 'results/nextclade.tsv' \
	--output-tree 'results/nextclade.auspice.json' \
	--input-qc-config 'src/qcRulesConfig.json' \
>results/nextclade.log

# Run nextalign
$BIN/nextalign \
	--sequences=ri_sequences.fa \
	--reference=src/reference.fasta \
	--genemap=src/genemap.gff \
	--genes=E,M,N,ORF10,ORF14,ORF1a,ORF1b,ORF3a,ORF6,ORF7a,ORF7b,ORF8,ORF9b,S \
	--output-dir=results/nextalign

# Quality control
python src/metadata.py ri_sequences.fa > ri_metadata.tsv
python src/nextstrain-diagnostics.py \
	--alignment results/nextalign/ri_sequences.aligned.fasta \
	--reference src/reference_seq.gb \
	--metadata ri_metadata.tsv \
	--output-diagnostics results/nextstrain-diagnostics.tsv \
	--output-flagged results/nextstrain-diagnostics-flagged.tsv \
	--output-exclusion-list results/nextstrain-diagnostics-exclusion.txt
python src/qc.py

### All following commands use results/qc-passed.csv ###

python src/mutations.py
python src/concern.py
Rscript src/num-sequences.R
Rscript src/num-voc-voi.R
Rscript src/top-lineages.R

# Run nextalign with references
cat ri_sequences_qc.fa src/references.fa > ri_sequences_qc_references.fa
$BIN/nextalign \
	--sequences=ri_sequences_qc_references.fa \
	--reference=src/reference.fasta \
	--genemap=src/genemap.gff \
	--genes=E,M,N,ORF10,ORF14,ORF1a,ORF1b,ORF3a,ORF6,ORF7a,ORF7b,ORF8,ORF9b,S \
	--output-dir=results/nextalign-references \
	--include-reference

# Tree
$BIN/iqtree2 -s results/nextalign-references/ri_sequences_qc_references.aligned.fasta --prefix results/iqtree2 -st DNA -m GTR+F --mem 8G
