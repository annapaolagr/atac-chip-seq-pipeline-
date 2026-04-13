include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { SAMTOOLS_INDEX }         from '../modules/local/samtools_index.nf' 
include { MACS3_ATAC }             from '../modules/local/macs3_atac.nf'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input    // Canale con le reads (meta, [r1, r2])
    ch_index    // Canale con l'indice del genoma

    main:
    ch_versions = Channel.empty()

    // 1. Controllo Qualità iniziale
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Trimming
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    // 3. Allineamento + Fixmate + Sort + Remove Duplicates
    // Ora BOWTIE2 restituisce direttamente il file *.removed.bam
    BOWTIE2 ( TRIMGALORE.out.reads, ch_index )
    ch_versions = ch_versions.mix(BOWTIE2.out.versions)

    // 4. Indicizzazione esterna
    // Genera il file .bai necessario per MACS3 e la visualizzazione
    SAMTOOLS_INDEX ( BOWTIE2.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.bai) // Se emette versioni, mixale

    // 5. Peak Calling per ATAC-seq
    // Passiamo sia il BAM che il BAI usando l'operatore .join per accoppiarli tramite 'meta'
    // Questo assicura che MACS3 trovi entrambi i file nella stessa cartella di lavoro
    ch_macs3_input = BOWTIE2.out.bam.join(SAMTOOLS_INDEX.out.bai)
    
    MACS3_ATAC ( ch_macs3_input )

    emit:
    bam      = BOWTIE2.out.bam
    bai      = SAMTOOLS_INDEX.out.bai
    peaks    = MACS3_ATAC.out.peaks
    versions = ch_versions
}
