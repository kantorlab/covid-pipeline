# covid-pipeline

## Installation

Create a new conda environment `covid-v1` with python 3.7:

    conda create -n covid-v1 python==3.7.10 
    conda activate covid-v1
    pip install snakemake

Install the desired version of pangolin and pangolin-data with the `update_pangolin.sh` script, for example:

    bash update_pangolin.sh 4.0.6 1.9

In the future, you could update the pangolin version using this script.

Install nextclade and nextalign in the `bin` subdirectory:

    mkdir -p bin
    curl -fsSL "https://github.com/nextstrain/nextclade/releases/latest/download/nextclade-Linux-x86_64" -o "bin/nextclade" && chmod +x bin/nextclade
    curl -fsSL "https://github.com/nextstrain/nextclade/releases/latest/download/nextalign-Linux-x86_64" -o "bin/nextalign" && chmod +x bin/nextalign

## Running

The input file of sequences in FASTA format should be named `ri_sequence.fa` (edit the `run.sh` script to use a different input filename).

The pipeline is designed to be submitted as a batch job to a SLURM cluster:

    sbatch run.sh

If you are running locally instead of on a cluster, simply execute the script in bash:

    bash run.sh

Results are written to the `results` subdirectory.

## License

The pipeline is freely available for non-commercial use under the license provided in [LICENSE.txt](https://github.com/kantorlab/covid-pipeline/blob/main/LICENSE.txt).

