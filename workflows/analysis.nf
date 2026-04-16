// 1. Inclusione dei moduli (aggiunto MACS3_CHIP)
include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { SAMTOOLS_SORT }          from '../modules/local/samtools_sort.nf'
include { PICARD_MARKDUPLICATES }  from '../modules/local/picard_markduplicates.nf'
include { MACS3_ATAC }             from '../modules/local/macs3_atac.nf'
include { MACS3_CHIP }             from '../modules/local/macs3_chip.nf'

workflow ATAC_CHIP_PIPELINE {
    take:
    ch_input    // [meta, [reads]]
    ch_index    // path_to_index_folder

    main:
    ch_versions = Channel.empty()

    // 1. Controllo Qualità iniziale
    FASTQC ( ch_input )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    // 2. Trimming
    TRIMGALORE ( ch_input )
    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    // 3. Allineamento
    BOWTIE2 ( 
        TRIMGALORE.out.reads, 
        ch_index 
    )
    ch_versions = ch_versions.mix(BOWTIE2.out.versions)

    // 4. Ordinamento Coordinate 
    SAMTOOLS_SORT ( BOWTIE2.out.bam )

    // 5. Rimozione Duplicati
    // Passiamo liste vuote [] se non usi fasta/fai, è più pulito di [[:], []]
    PICARD_MARKDUPLICATES ( 
        SAMTOOLS_SORT.out.bam, 
        [], 
        [] 
    )
    ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions)

    // --- LOGICA DI SELEZIONE PROTOCOLLO ---

    ch_peaks = Channel.empty()

    if (params.protocol == 'atac') {
        
        // --- LOGICA ATAC-SEQ ---
        // MACS3_ATAC riceve direttamente il BAM deduplicato
        MACS3_ATAC ( PICARD_MARKDUPLICATES.out.bam )
        ch_peaks = MACS3_ATAC.out.peaks
        ch_versions = ch_versions.mix(MACS3_ATAC.out.versions)

    } else if (params.protocol == 'chip') {
        
        // --- LOGICA CHIP-SEQ (ACCOPPIAMENTO IP vs INPUT) ---
        ch_bams = PICARD_MARKDUPLICATES.out.bam

        // Identifichiamo i controlli (quelli con antibody 'none' o vuoto nel CSV)
        ch_control_bams = ch_bams
            .filter { meta, bam -> meta.antibody == 'none' || !meta.antibody }
            .map { meta, bam -> [ meta.id, bam ] }

        // Identifichiamo le IP e le uniamo ai rispettivi controlli
        ch_macs3_chip_input = ch_bams
            .filter { meta, bam -> meta.antibody && meta.antibody != 'none' }
            .map { meta, bam -> [ meta.control, meta, bam ] } // chiave di join: meta.control
            .join(ch_control_bams)
            .map { id_ctrl, meta, bam_ip, bam_ctrl -> [ meta, bam_ip, bam_ctrl ] }

        MACS3_CHIP ( ch_macs3_chip_input )
        ch_peaks = MACS3_CHIP.out.peaks
        ch_versions = ch_versions.mix(MACS3_CHIP.out.versions)
    }

    emit:
    bam      = PICARD_MARKDUPLICATES.out.bam
    bai      = PICARD_MARKDUPLICATES.out.bai
    peaks    = ch_peaks
    versions = ch_versions
}
