# atac-chip-seq-pipeline-

-----

# ATAC & ChIP-seq Analysis Pipeline

**Nextflow DSL2 pipeline for automated analysis of ChIP-seq and ATAC-seq data.**

[](https://www.nextflow.io/)
[](https://www.docker.com/)

## Introduction

This pipeline is designed to process chromatin sequencing data starting from raw files (`FASTQ`) through to peak calling and annotation.

The workflow is extremely flexible: it automatically detects whether samples are **Single-End** or **Paired-End** based on the samplesheet content and adjusts MACS3 parameters accordingly.

## Usage

The pipeline can be executed directly from GitHub. Nextflow will automatically handle code download and container management.

```bash
nextflow run annapaolagr/atac-chip-seq-pipeline- \
    -latest \
    -profile docker \
    --input samplesheet.csv \
    --protocol chip \
    --genome GRCh38 \
    --outdir "results"
```

### Main Parameters:

  * `-latest`: Forces the download of the latest code version from GitHub.
  * `-profile docker`: Runs every tool within a dedicated container (recommended).
  * `--protocol`: Defines the type of analysis (`chip` or `atac`).
  * `--genome`: Specifies the reference genome (e.g., `GRCh38` or `hg38`).
  * `--input`: Path to the samplesheet CSV file.

-----

## Pipeline Summary

The workflow performs the following steps:

1.  **Quality Control**: Raw read quality control ([FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)).
2.  **Trimming**: Removal of adapters and low-quality bases ([Trim Galore\!](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/)).
3.  **Alignment**: Read mapping to the reference genome ([Bowtie2](http://bowtie-bio.sourceforge.net/bowtie2/index.shtml)).
4.  **Duplicates Management**: Identification and removal of duplicates ([Picard MarkDuplicates](https://broadinstitute.github.io/picard/)).
5.  **Filtering**: Removal of reads mapped to blacklisted regions, non-primary alignments, or reads with low mapping quality ([SAMtools](http://www.htslib.org/)).
6.  **BigWig Generation**: Creation of normalized files (RPKM) for visualization on IGV ([deepTools](https://deeptools.readthedocs.io/)).
7.  **Peak Calling**: Identification of enriched regions (Narrow/Broad) ([MACS3](https://github.com/macs3-project/MACS)).
8.  **Annotation**: Peak annotation relative to gene features ([HOMER](http://homer.ucsd.edu/homer/)).
9.  **QC Metrics**: Calculation of the Fraction of Reads in Peaks (FRiP score).
10. **MultiQC**: Generation of a final interactive report with statistics from every step ([MultiQC](https://multiqc.info/)).

-----

## Input (Samplesheet)

The `samplesheet.csv` file must be formatted as follows:

```csv
sample,fastq_1,fastq_2,antibody,control
IP_gH2AX_DOXO_1_S19_R1_001,data/IP_gH2AX_DOXO_1_S19_R1_001.fastq.gz,,IgG,IP_IgG_DOXO_1_S22_R1_001
IP_IgG_DOXO_1_S22_R1_001,data/IP_IgG_DOXO_1_S22_R1_001.fastq.gz,,,
```

The columns must be structured as follows:

  * **sample**: Unique name for the sample.
  * **fastq\_1**: Full path to FastQ file 1 (Read 1). Must end in `.fastq.gz` or `.fq.gz`.
  * **fastq\_2**: Full path to FastQ file 2 (Read 2). Leave **empty** for Single-End samples.
  * **antibody**: Name of the antibody used (e.g., `H3K27me3`).
  * **control**: Name of the sample to be used as control (must match a value in the `sample` column).

## Output

Results are organized in the `results/` folder:

  * **`00_MultiQC/`**: Interactive HTML report (including genome info and tool versions).
  * **`01_fastqc/`**: Initial read quality.
  * **`04_alignment/`**: Filtered and indexed BAM files.
  * **`05_peaks/`**: `.narrowPeak` / `.broadPeak` files and MACS3 logs.
  * **`06_bigwig/`**: `.bw` files for track visualization.
  * **`07_homer_annotation/`**: Gene annotation tables.

-----

## Credits

Developed with passion by **Annapaola** (@annapaolagr).

> *Note: The MultiQC report is configured to display configuration information (Genome/Protocol) at the top and the software versions summary at the bottom, following nf-core standards.*

-----
