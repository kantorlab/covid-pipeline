#!/bin/bash
#SBATCH -c 1
#SBATCH --mem=8G
#SBATCH -t 1:00:00

set -e
CONDA=/gpfs/data/rkantor/conda/bin
BIN=/gpfs/data/rkantor/bin

mkdir -p results

# Run Pangolin
source $CONDA/activate pangolin
pangolin ri_sequences.fa -o results/pangolin --alignment --no-temp

# Run nextalign
$BIN/nextalign \
	--sequences=ri_sequences.fasta \
	--reference=src/reference.fasta \
	--genemap=src/genemap.gff \
	--genes=E,M,N,ORF10,ORF14,ORF1a,ORF1b,ORF3a,ORF6,ORF7a,ORF7b,ORF8,ORF9b,S \
	--output-dir=results/nextalign

# Generate additional results
python src/metadata.py ri_sequences.fa > ri_metadata.tsv
python src/mutations.py
Rscript src/cumulative.R
python src/concern.py

