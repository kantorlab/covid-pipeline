import json
import pandas as pd
import numpy as np

concern = [
	"S:S13I",
	"S:A67V",
	"S:H69-",
	"S:V70-",
	"S:T95I",
	"S:Y144-"
	"S:W152C",
	"S:D253G",
	"S:K417N",
	"S:K417T",
	"S:L452R",
	"S:S477N",
	"S:E484K",
	"S:N501Y",
	"S:A570D",
	"S:P681H",
	"S:A701V",
	"S:Q677H",
	"S:F888L",
	"S:S494P",
	"S:V1176F",
]

mutations = json.load(open("results/mutations.json"))
seqs = pd.read_csv("results/qc-passed.csv", usecols=["strain", "date", "pangolin.lineage"]).sort_values("date")

detail = []

for row in seqs.itertuples():
    for mutation in mutations.get(row.strain, []):
        if mutation in concern:
            detail.append([row.strain, row.date, mutation])

pd.DataFrame.from_records(detail, columns=["sample", "date", "mutation"]).to_csv("results/concern-long.csv", index=False)

seqs["mutations"] = [
    ",".join(mutation for mutation in concern if mutation in frozenset(mutations.get(row.strain, [])))
    for row in seqs.itertuples()
]
print(seqs["mutations"].value_counts())
seqs.to_csv("results/concern.csv", index=False)

