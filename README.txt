To launch the script type this in the shell: 'snakemake --cores all --use-conda'

In configfile.json:
	directory is the directory of the reads used
	samples are the list of reads used
	genomeDir is the directory of genome file used
	genomeName is the name of the genome file used

rule duplicate : ligne 83 et 84 il y a une erreur j'ai oublié de mettre les triples guillemets

To launch Snakefile2 : snakemake -s Snakefile2 --cores all --use-conda
