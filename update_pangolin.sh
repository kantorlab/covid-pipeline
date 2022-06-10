#!/bin/bash
set -e
VERSION=$1
DATA=$2
if [[ -z $VERSION || -z $DATA ]]
then
	echo "usage: bash update-pangolin.sh NEW_PANGOLIN_VERSION NEW_DATA_VERSION"
	exit 1
fi
source /gpfs/data/rkantor/conda/bin/activate covid-v1
pip uninstall -y pangolin pangolin-data scorpio constellations
pip install git+https://github.com/cov-lineages/scorpio.git
pip install git+https://github.com/cov-lineages/constellations.git
pip install git+https://github.com/cov-lineages/pangolin-data.git@v${DATA}
pip install git+https://github.com/cov-lineages/pangolin.git@v${VERSION}
pangolin -v
echo "Success!"
