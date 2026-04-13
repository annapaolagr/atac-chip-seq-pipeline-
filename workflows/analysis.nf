include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { SAMTOOLS_INDEX }         from '../modules/local/samtools_index.nf' 
include { MACS3_ATAC }             from '../modules/local/macs3_atac.nf'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input    
    ch_index    

    main:
    ch_versions = Channel.empty()

    // 1. Controllo Qualità iniziale
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Trimming
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    // 3. Allineamento + Rimozione Duplicati (All-in-one Pipe)
    // Produce direttamente il file *.removed.bam
    BOWTIE2 ( TRIMGALORE.out.reads, ch_index )
    ch_versions = ch_versions.mix(BOWTIE2.out.versions)

    // 4. Indicizzazione esterna
    // Importante: passiamo il BAM generato da Bowtie2
    SAMTOOLS_INDEX ( BOWTIE2.out.bam )
    
    // CORREZIONE: Mixiamo le versioni di Samtools, non il file .bai!
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    // 5. Peak Calling per ATAC-seq
    // Usiamo .join() per creare una tuple [meta, bam, bai]
    // Questo garantisce che ogni campione abbia il suo indice corrispondente
    ch_macs3_input = BOWTIE2.out.bam.join(SAMTOOLS_INDEX.out.bai)
    
    MACS3_ATAC ( ch_macs3_input )

    emit:
    bam      = BOWTIE2.out.bam
    bai      = SAMTOOLS_INDEX.out.bai
    peaks    = MACS3_ATAC.out.peaks
    versions = ch_versions
}
