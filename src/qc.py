import pandas as pd

ri = pd.read_csv("ri_metadata.tsv", sep="\t")

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

failed = (
    (ri["pangolin.status"] != "passed_qc") |
    (ri["nextclade.qc.overallStatus"] == "bad") |
    (ri["nextstrain.flagging_reason"].notnull())
)

ri[failed].to_csv("results/qc-failed.csv", index=False)
ri[~failed].to_csv("results/qc-passed.csv", index=False)

