import pandas as pd
from Bio import SeqIO

ri = pd.read_csv("ri_metadata.tsv", sep="\t").sort_values("date")

# Join Pangolin
pangolin = pd.read_csv("results/pangolin/lineage_report.csv")
columns = dict((col, "pangolin." + col) for col in pangolin.columns)
columns["taxon"] = "strain"
ri = ri.merge(pangolin.rename(columns=columns), how="outer", on="strain", validate="1:1")

# Join NextClade
nextclade = pd.read_csv("results/nextclade.tsv", sep="\t")
columns = dict((col, "nextclade." + col) for col in nextclade.columns)
columns["seqName"] = "strain"
ri = ri.merge(nextclade.rename(columns=columns), how="outer", on="strain", validate="1:1")

# Join NextStrain
nextstrain = pd.read_csv(
    "results/nextstrain-diagnostics-flagged.tsv",
    sep="\t",
    usecols=["strain", "flagging_reason"]).rename(
	columns={"flagging_reason": "nextstrain.flagging_reason"}
    )
ri = ri.merge(nextstrain, how="outer", on="strain", validate="1:1")

# Join CDC
cdc = pd.read_csv("src/cdc-voc-voi.tsv", sep="\t")
ri = ri.merge(cdc, how="left", on="pangolin.lineage")

failed = (
    (ri["pangolin.status"] != "passed_qc") |
    (ri["strain"].str.startswith("hCoV-19/USA/RI_RKL") & (
        (ri["nextclade.qc.overallStatus"] == "bad") |
        (ri["nextstrain.flagging_reason"].notnull())
    ))
)

ri[failed].to_csv("results/qc-failed.csv", index=False)
ri[~failed].to_csv("results/qc-passed.csv", index=False)

# Filter sequences
passed = frozenset(ri[~failed]["strain"])
with open("ri_sequences_qc.fa", "w") as f:
    for record in SeqIO.parse("ri_sequences.fa", "fasta"):
        if record.id in passed:
            print(">"+record.id, file=f)
            print(record.seq, file=f)

