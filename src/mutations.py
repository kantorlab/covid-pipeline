import json
import os
import pandas as pd
from Bio import SeqIO
from collections import defaultdict

dirname = os.path.dirname(__file__)

genes = ["E","M","N","ORF10","ORF14","ORF1a","ORF1b","ORF3a","ORF6","ORF7a","ORF7b","ORF8","ORF9b","S"]

genemap = pd.read_csv(os.path.join(dirname, "genes.csv"), index_col="gene")

nt_ref = next(SeqIO.parse(os.path.join(dirname, "reference.fasta"), "fasta")).seq

mutations = defaultdict(list)

for gene in genes:

    # Translate nt sequence to aa
    ref = nt_ref[genemap.loc[gene, "start"]-1:genemap.loc[gene, "end"]].translate()
    assert "*" not in ref[:-1], ref

    # Call variants
    for seq in SeqIO.parse(f"results/nextalign/ri_sequences.gene.{gene}.fasta", "fasta"):
        assert len(seq) == len(ref), seq.id
        for i, (aa0, aa1) in enumerate(zip(ref, seq.seq), start=1):
            assert aa0 != "-" and aa0 != "X"
            if aa1 != "X" and aa1 != aa0:
                mutations[seq.id].append(f"{gene}:{aa0}{i}{aa1}")

with open("results/mutations.json", "w") as f:
    json.dump(mutations, f, sort_keys=True, indent=2)

