configfile: "configfile.json"



rule target:
	input:
		"results/multibam.npz"


rule unzip: #snakemake gere la creation des fichiers manquant
	input:
		expand("{directory}/{{sample}}.fastq.gz", directory=config["directory"])
	output:
		temp("tmp/{sample}.fastq")
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

rule cutadapt:
	input:
		r1=expand("{directory}/{{sample}}_1.fastq.gz", directory=config["directory"]),
		r2=expand("{directory}/{{sample}}_2.fastq.gz", directory=config["directory"])
	params:
		m=expand("{m}", m=config["minlength"]),
		q=expand("{q}", q=config["qualtrim"])
	output:
		o1=temp("tmp/{sample}_filter1.fastq"),
		o2=temp("tmp/{sample}_filter2.fastq")
	shell:
		"cutadapt -q {params.q} -m {params.m} -o {output.o1} -p {output.o2} {input.r1} {input.r2}"
		
		
rule buildIndex:
	input:
		genome=expand("{dir}/{name}.fasta", dir=config["genomeDir"], name=config["genomeName"])
	output:
		expand("{dir}/{name}.1.bt2", dir=config["genomeDir"], name=config["genomeName"])
	threads: workflow.cores*0.9
	shell:
		"""bowtie-build --threads {threads} -f {input.genome} {output} """


rule alignement:
	input:
		r1= "tmp/{sample}_filter1.fastq",
		r2= "tmp/{sample}_filter2.fastq",
		index= expand("{dir}/{name}.1.bt2", dir=config["genomeDir"], name=config["genomeName"])
	output:
		sam="tmp/{sample}.sam"
	threads: 4
	params: ind=expand("{dir}/{ind}", ind=config["genomeName"], dir=config["genomeDir"])
	shell:
		"bowtie2 -q --threads {threads} -x {params.ind} -1 {input.r1} -2 {input.r2} -S {output.sam}"

rule trimming:
	input:
		"tmp/{sample}.sam"
	output:
		bam="tmp/{sample}.bam",
		sorted="tmp/{sample}_sorted.bam"
	shell:
		"""samtools view -Sb {input} > {output.bam};
		   samtools sort {output.bam} > {output.sorted};
		   samtools index {output.sorted}"""

rule duplicate:
	input:
		"tmp/{sample}_sorted.bam"
	output:
		bam="results/{sample}_duplicate.bam",
		txt="results/{sample}_duplicate.txt"
	shell:
		"picard-tools MarkDuplicates I={input} O={output.bam} M={output.txt};
		samtools index {output.bam}"

rule multibam:
	input:
		[
			expand("results/{samp}_duplicate.bam", samp=sample)
			for sample in config["samples"]
		]
	output:
		"results/multibam.npz"
	shell:
		"multiBamSummary bins --bamfiles {input} -o {output}"
		
rule correlation:
	input:
		"results/multibam.npz"
		
	
