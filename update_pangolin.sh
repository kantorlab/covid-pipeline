#!/bin/bash
set -e
VERSION=$1
if [ -z $VERSION ]
then
	echo "usage: bash update-pangoloin.sh NEW_PANGOLIN_VERSION"
	exit 1
fi
source /gpfs/data/rkantor/conda/bin/activate covid-v1
pip uninstall -y pangolin pangoLEARN scorpio
pip install git+https://github.com/cov-lineages/scorpio.git
pip install git+https://github.com/cov-lineages/pangoLEARN.git
pip install git+https://github.com/cov-lineages/pangolin.git@v${VERSION}
pangolin -v
echo "Success!"
