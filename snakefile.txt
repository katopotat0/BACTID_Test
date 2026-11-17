SAMPLES = ["isolateA_732"]

rule all:
    input:
        expand("results/qc/{sample}_{read}_fastqc.html", sample=SAMPLES, read=["1", "2"]),
        expand("results/qc/{sample}_{read}_fastqc.zip", sample=SAMPLES, read=["1", "2"]),
        expand("results/trimmed/{sample}_{read}.trim.fastq.gz", sample=SAMPLES, read=["1", "2"]),
        expand("results/trimmed/{sample}_fastp.json", sample=SAMPLES),
        expand("results/trimmed/{sample}_fastp.html", sample=SAMPLES),
        #expand("results/taxonomy/{sample}_gambit.csv", sample=SAMPLES)

rule fastqc:
    input:
        read1 = "/mnt/cluster_storage/data/ref/bact_samples/raw_reads/{sample}_1.fastq.gz",
        read2 = "/mnt/cluster_storage/data/ref/bact_samples/raw_reads/{sample}_2.fastq.gz"
    output:
        html_1 = "results/qc/{sample}_1_fastqc.html",
        zip_1  = "results/qc/{sample}_1_fastqc.zip",
        html_2 = "results/qc/{sample}_2_fastqc.html",
        zip_2  = "results/qc/{sample}_2_fastqc.zip"
    container:
        "docker://quay.io/biocontainers/fastqc:0.13.0--hdfd78af_0"
    shell:
        """
        mkdir -p results/qc
        fastqc -o results/qc {input.read1} {input.read2}
        """

rule fastp:
    input:
        read1 = "/mnt/cluster_storage/data/ref/bact_samples/raw_reads/{sample}_1.fastq.gz",
        read2 = "/mnt/cluster_storage/data/ref/bact_samples/raw_reads/{sample}_2.fastq.gz"
    output:
        trimmed1   = "results/trimmed/{sample}_1.trim.fastq.gz",
        trimmed2   = "results/trimmed/{sample}_2.trim.fastq.gz",
        fastp_json = "results/trimmed/{sample}_fastp.json",
        fastp_html = "results/trimmed/{sample}_fastp.html"
    container:
        "docker://quay.io/biocontainers/fastp:1.4.0--h43da1c4_0"
    shell:
        """
        mkdir -p results/trimmed
        fastp \
            --in1 {input.read1} \
            --in2 {input.read2} \
            --out1 {output.trimmed1} \
            --out2 {output.trimmed2} \
            --json {output.fastp_json} \
            --html {output.fastp_html}
        """
