#!/bin/bash
#SBATCH -c 1
#SBATCH --mem=20G
#SBATCH -t 12:00:00

set -e
BIN=bin
conda activate covid-v1

mkdir -p results

# Run pangolin
pangolin ri_sequences.fa -o results/pangolin --alignment --no-temp

# Run nextclade
$BIN/nextclade dataset get -n sars-cov-2 -o nextclade_dataset
$BIN/nextclade run \
	--input-fasta 'ri_sequences.fa' \
	--input-dataset 'nextclade_dataset' \
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

