configfile: "config.yml"


rule all:
    input: 
       expand("results/qc/{sample}_fastqc.html", sample=config.get("sample")),
       expand("results/qc/{sample}_fastqc.zip", sample=config.get("sample")),
       expand("results/trimmed/{isolate}_1.trim.fastq.gz", isolate=config.get("isolate")),
       expand("results/trimmed/{isolate}_2.trim.fastq.gz", isolate=config.get("isolate")),
       expand("results/trimmed/{isolate}.fastp.json", isolate=config.get("isolate")),
       expand("results/assembly/{isolate}_contigs.fa", isolate=config.get("isolate")),
       expand("results/quast/{isolate}/report.tsv", isolate=config.get("isolate")),
       expand("results/gambit/{isolate}_gambit.csv", isolate=config.get("isolate")),
       expand("results/mlst/{isolate}_mlst.tsv", isolate=config.get("isolate")),
       expand("results/amr/{isolate}_amr.tsv", isolate=config.get("isolate")),
       expand("results/plasmids/{isolate}.tsv", isolate=config.get("isolate"))


rule fastqc:
    input:
        "data/bact_samples/{sample}.fastq.gz"
    output:
        html = "results/qc/{sample}_fastqc.html",
        zip = "results/qc/{sample}_fastqc.zip"
    threads: 2
    container:
        "docker://quay.io/biocontainers/fastqc:0.13.0--hdfd78af_0"
    shell: 
        """
        mkdir -p results/qc
        fastqc {input} --outdir results/qc
        """


rule trim:
    input:
        r1 = "data/bact_samples/{isolate}_1.fastq.gz",
        r2 = "data/bact_samples/{isolate}_2.fastq.gz"
    output:
        r1 = "results/trimmed/{isolate}_1.trim.fastq.gz",
        r2 = "results/trimmed/{isolate}_2.trim.fastq.gz",
        json = "results/trimmed/{isolate}.fastp.json"
    container:
        "docker://staphb/fastp:0.23.4"
    shell:
        """
        fastp \
            --in1 {input.r1} \
            --in2 {input.r2} \
            --out1 {output.r1} \
            --out2 {output.r2} \
            --json {output.json} 
        """


rule contig_de_novo:
    input:
        r1 = "results/trimmed/{isolate}_1.trim.fastq.gz",
        r2 = "results/trimmed/{isolate}_2.trim.fastq.gz"
    output:
        contigs = "results/assembly/{isolate}_contigs.fa"
    params: 
        outdir = "results/assembly"
    container: 
        "docker://staphb/shovill:1.4.2"
    shell:
        """
        shovill \
            --R1 {input.r1} \
            --R2 {input.r2} \
            --outdir {params.outdir} \
            --force
        """


rule qa:
    input: "results/assembly/{isolate}_contigs.fa"
    output: "results/quast/{isolate}/report.tsv"
    container: "docker://staphb/quast:5.3.0"
    shell:
       """
       quast.py \
          {input} \
          -o results/quast/{wildcards.isolate}
       """

rule taxa_ident:
    input: "results/assembly/{isolate}_contigs.fa"
    output:"results/gambit/{isolate}_gambit.csv"
    container: "docker://staphb/gambit:1.2.0"
    shell:
       """
       gambit \
          --db /gambit-db \
          query \
          -o {output} \
          {input}
       """


rule mlst:
    input: "results/assembly/{isolate}_contigs.fa"
    output: "results/mlst/{isolate}_mlst.tsv"
    container: "docker://staphb/mlst:2.35.0"
    shell: 
        """
        mlst {input} > {output}
        """


rule amr:
    input: "results/assembly/{isolate}_contigs.fa"
    output: "results/amr/{isolate}_amr.tsv"
    container: "docker://staphb/ncbi-amrfinderplus:4.2.7-2026-10-29.1"
    shell:
        """
        amrfinder \
        -n {input} \
        -o {output}
        """


rule find_plasmid:
    input: "results/assembly/{isolate}_contigs.fa"
    output: "results/plasmids/{isolate}.tsv"
    container: "docker://staphb/abricate:1.4.0"
    shell:
        """
        abricate {input} > {output}
        """
