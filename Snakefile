configfile: "configfile.json"

rule target:
	input:
		expand("results/fastqc_init/{sample}_fastqc.html", sample=config["samples"])


rule unzip: #snakemake gere la creation des fichiers manquant
	input:
		expand("{directory}/{{sample}}.fastq.gz", directory=config["directory"])
	output:
		"tmp/{sample}.fastq"
	shell:
		"""gunzip -c {input} > {output}"""
		
rule fastqc_init:
	input:
		"tmp/{sample}.fastq"
	output:
		"results/fastqc_init/{sample}_fastqc.html"
	threads: 2
	conda:
		"env.yaml"
	shell:
		"""fastqc {input} -o results/fastqc_init """

