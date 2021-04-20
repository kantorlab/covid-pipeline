import sys

months = {
    "JAN": "01",
    "FEB": "02",
    "MAR": "03",
    "APR": "04",
    "MAY": "05",
    "JUN": "06",
    "JUL": "07",
    "AUG": "08",
    "SEP": "09",
    "OCT": "10",
    "NOV": "11",
    "DEC": "12",
}

print("strain", "virus", "date", "region", "country", "division", "date_submitted", sep="\t")

for line in open(sys.argv[1]):
    if line.startswith(">"):
        ID = line.strip()[1:]
        try:
            if ID[-3] == "-":
                date = ID[-10:]
            else:
                year = ID[-9:-5]
                month = months[ID[-5:-2]]
                day = ID[-2:]
                date = f"{year}-{month}-{day}"
            print(ID, "ncov", date, "North America", "USA", "Rhode Island", date, sep="\t")
        except KeyError:
            print("WARNING: droping sequence", ID, "with bad date formatting", file=sys.stderr)

