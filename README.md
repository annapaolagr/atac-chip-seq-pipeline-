# atac-chip-seq-pipeline-

-----

# 🧬 ATAC & ChIP-seq Analysis Pipeline

**Pipeline Nextflow DSL2 per l'analisi automatizzata di dati ChIP-seq e ATAC-seq.**

[](https://www.nextflow.io/)
[](https://www.docker.com/)

## 📝 Introduzione

Questa pipeline è stata progettata per processare dati di sequenziamento della cromatina partendo dai file grezzi (`FASTQ`) fino alla chiamata dei picchi (`Peak Calling`) e alla loro annotazione.

Il workflow è estremamente flessibile: riconosce automaticamente se i campioni sono **Single-End** o **Paired-End** basandosi sul contenuto del samplesheet e adatta i parametri di MACS3 di conseguenza.

## 🚀 Usage

La pipeline può essere eseguita direttamente da GitHub. Nextflow gestirà automaticamente il download del codice e l'uso dei container.

```bash
nextflow run annapaolagr/atac-chip-seq-pipeline- \
    -latest \
    -profile docker \
    --input samplesheet.csv \
    --protocol chip \
    --genome GRCh38 \
    --outdir "results"
```

### Parametri principali:

  * `-latest`: Forza il download dell'ultima versione del codice da GitHub.
  * `-profile docker`: Esegue ogni tool all'interno di un container dedicato (consigliato).
  * `--protocol`: Definisce il tipo di analisi (`chip` o `atac`).
  * `--genome`: Specifica il genoma di riferimento (es. `GRCh38` o `hg38`).
  * `--input`: Percorso al file CSV dei campioni.

-----

## 📊 Pipeline Summary

Il workflow esegue i seguenti passaggi:

1.  **Quality Control**: Controllo qualità delle reads grezze ([FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)).
2.  **Trimming**: Rimozione di adapter e basi di bassa qualità ([Trim Galore\!](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/)).
3.  **Alignment**: Mappatura delle reads sul genoma di riferimento ([Bowtie2](http://bowtie-bio.sourceforge.net/bowtie2/index.shtml)).
4.  **Duplicates Management**: Identificazione e rimozione dei duplicati ([Picard MarkDuplicates](https://broadinstitute.github.io/picard/)).
5.  **Filtering**: Rimozione di reads mappate su regioni blacklist, reads non primarie o con bassa qualità di mappa ([SAMtools](http://www.htslib.org/)).
6.  **BigWig Generation**: Creazione di file normalizzati (RPKM) per la visualizzazione su IGV ([deepTools](https://deeptools.readthedocs.io/)).
7.  **Peak Calling**: Identificazione delle regioni arricchite (Narrow/Broad) ([MACS3](https://github.com/macs3-project/MACS)).
8.  **Annotation**: Annotazione dei picchi rispetto alle feature geniche ([HOMER](http://homer.ucsd.edu/homer/)).
9.  **QC Metrics**: Calcolo della frazione di reads nei picchi (FRiP score).
10. **MultiQC**: Generazione di un report interattivo finale con tutte le statistiche di ogni step ([MultiQC](https://multiqc.info/)).

-----

## 📋 Input (Samplesheet)

Il file `samplesheet.csv` deve essere formattato come segue:

Snippet di codice
sample,fastq_1,fastq_2,antibody,control
IP_gH2AX_DOXO_1_S19_R1_001,data/IP_gH2AX_DOXO_1_S19_R1_001.fastq.gz,,IgG,IP_IgG_DOXO_1_S22_R1_001
IP_IgG_DOXO_1_S22_R1_001,data/IP_IgG_DOXO_1_S22_R1_001.fastq.gz,,, 


Le colonne devono essere strutturate come segue:

sample	= Nome univoco del campione.
fastq_1	= Percorso completo al file FastQ 1 (Read 1). Deve finire in .fastq.gz o .fq.gz.
fastq_2	= Percorso completo al file FastQ 2 (Read 2). Lasciare vuoto per campioni Single-End.
antibody	= Nome dell'anticorpo utilizzato (es. H3K27me3).
control	= Nome del campione da utilizzare come controllo (deve corrispondere a un valore nella colonna sample).

## 📂 Output

I risultati sono organizzati nella cartella `results/`:

  * **`00_MultiQC/`**: Report interattivo HTML (con info genoma e versioni tool).
  * **`01_fastqc/`**: Qualità iniziale delle reads.
  * **`04_alignment/`**: File BAM filtrati e indicizzati.
  * **`05_peaks/`**: File `.narrowPeak` / `.broadPeak` e log di MACS3.
  * **`06_bigwig/`**: File `.bw` per la visualizzazione dei tracciati.
  * **`07_homer_annotation/`**: Tabelle di annotazione dei geni.

-----

## ✨ Credits

Sviluppato con passione da **Annapaola** (@annapaolagr).

> *Note: Il report MultiQC è configurato per mostrare le informazioni di configurazione (Genoma/Protocollo) in cima e il riepilogo delle versioni software in fondo, seguendo gli standard nf-core.*

-----
