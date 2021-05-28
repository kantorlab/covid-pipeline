import json
import pandas as pd
import numpy as np

concern = {
        "L5F": ["B.1.526"],
        "S13I": ["B.1.429"],
        "L18F": ["P.1"],
        "T19R": ["B.1.617.2", "B.1.617.3"],
        "T20N": ["P.1"],
        "P26S": ["P.1"],
        "A67V": ["B.1.525"],
        "D80G": ["B.1.526.1"],
        "D80A": ["B.1.351"],
        "T95I": ["B.1.526", "B.1.617.1"],
        "D138Y": ["P.1"],
        "G142D": ["B.1.617.1", "B.1.617.2", "B.1.617.3"],
        "W152C": ["B.1.429"],
        "E154K": ["B.1.617.1"],
        "F157S": ["B.1.526.1"],
        "R158G": ["B.1.617.2"],
        "R190S": ["P.1"],
        "D215G": ["B.1.351"],
        "D253G": ["B.1.526"],
        "K417N": ["B.1.351"],
        "K417T": ["P.1"],
        "L452R": ["B.1.427", "B.1.429", "B.1.526.1", "B.1.617", "B.1.617.1", "B.1.617.2", "B.1.617.3"],
        "S477N": ["B.1.526"],
        "T478K": ["B.1.617.2"],
        "E484K": ["B.1.526", "B.1.525", "P.2", "B.1.1.7", "P.1", "B.1.351"],
        "E484Q": ["B.1.617", "B.1.617.1", "B.1.617.3"],
        "S494P": ["B.1.1.7"],
        "N501Y": ["B.1.1.7", "P.1", "B.1.351"],
        "F565L": ["P.2"],
        "A570D": ["B.1.1.7"],
        "H655Y": ["P.1"],
        "Q677H": ["B.1.525"],
        "P681H": ["B.1.1.7"],
        "P681R": ["B.1.617.1", "B.1.617.2", "B.1.617.3"],
        "A701V": ["B.1.526", "B.1.351"],
        "T716I": ["B.1.1.7"],
        "T791I": ["B.1.526.1"],
        "T859N": ["B.1.526.1"],
        "F888L": ["B.1.525"],
        "D950H": ["B.1.526.1"],
        "D950N": ["B.1.617.2", "B.1.617.3"],
        "S982A": ["B.1.1.7"],
        "T1027I": ["P.1"],
        "Q1071H": ["B.1.617.1"],
        "D1118H": ["B.1.1.7"],
        "V1176F": ["P.2"],
        "K1191N": ["B.1.1.7"],
        "H69-": ["B.1.525", "B.1.1.7"],
        "V70-": ["B.1.525", "B.1.1.7"],
        "Y144-": ["B.1.525", "B.1.526.1", "B.1.1.7"],
        "E156-": ["B.1.617.2"],
        "F157-": ["B.1.617.2"],
        "L241-": ["B.1.351"]
}
concern = dict(("S:"+key, value) for key, value in concern.items())

mutations = json.load(open("results/mutations.json"))
seqs = pd.read_csv("results/qc-passed.csv", usecols=["strain", "date", "pangolin.lineage", "cdc.classification"]).sort_values("date")

detail = []

for _, row in seqs.iterrows():
    for mutation in mutations.get(row.strain, []):
        if mutation in concern:
            if not row["pangolin.lineage"] in concern[mutation]:
                detail.append([row.strain, row.date, mutation])

detail = pd.DataFrame.from_records(detail, columns=["strain", "date", "mutation"])
detail.to_csv("results/concern-long.csv", index=False)

detail["value"] = 1
detail = detail.pivot(index="strain", columns="mutation", values="value")\
               .fillna(0)\
               .astype(int)\
               .reset_index()\
               .merge(seqs[["strain", "date"]], how="left", on="strain")\
               .sort_values("date")
detail.to_csv("results/concern.csv", index=False)
print(detail.describe())

