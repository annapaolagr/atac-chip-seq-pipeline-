// 1.
include { FASTQC }                 from '../modules/local/fastqc.nf'
include { TRIMGALORE }             from '../modules/local/trimgalore.nf'
include { BOWTIE2 }                from '../modules/local/bowtie2.nf'
include { SAMTOOLS_SORT }          from '../modules/local/samtools_sort.nf'
include { PICARD_MARKDUPLICATES }  from '../modules/local/picard_markduplicates.nf'
include { MACS3_ATAC_NARROW } from '../modules/local/macs3_atac_narrow.nf'
include { MACS3_ATAC_BROAD }  from '../modules/local/macs3_atac_broad.nf'
include { MACS3_CHIP_NARROW }      from '../modules/local/macs3_chip_narrow.nf'
include { MACS3_CHIP_BROAD }       from '../modules/local/macs3_chip_broad.nf'



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
        
      MACS3_ATAC_NARROW ( ch_final_bams )
        MACS3_ATAC_BROAD  ( ch_final_bams )

        ch_peaks = MACS3_ATAC_NARROW.out.peaks.mix(MACS3_ATAC_BROAD.out.peaks)
        ch_versions = ch_versions.mix(
            MACS3_ATAC_NARROW.out.versions, 
            MACS3_ATAC_BROAD.out.versions
        )
    }

else if (params.protocol == 'chip') {
        
        // --- LOGICA CHIP-SEQ (ACCOPPIAMENTO IP vs INPUT) ---
        ch_bams = PICARD_MARKDUPLICATES.out.bam

        // 1. Identifichiamo i controlli (Input/IgG)
        // Creiamo una mappa [ ID_Controllo, File_BAM ]
        ch_control_bams = ch_bams
            .filter { meta, bam -> meta.antibody == 'none' || !meta.antibody || meta.antibody == '' }
            .map { meta, bam -> [ meta.id, bam ] }

        // 2. Identifichiamo le IP e le uniamo ai controlli tramite la colonna 'control' del CSV
        ch_macs3_chip_input = ch_bams
            .filter { meta, bam -> meta.antibody && meta.antibody != 'none' && meta.antibody != '' }
            .map { meta, bam -> [ meta.control, meta, bam ] } 
            .join(ch_control_bams)
            .map { id_ctrl, meta, bam_ip, bam_ctrl -> [ meta, bam_ip, bam_ctrl ] }

        // 3. Lanciamo i due moduli in parallelo
        MACS3_CHIP_NARROW ( ch_macs3_chip_input )
        MACS3_CHIP_BROAD  ( ch_macs3_chip_input )

        // 4. Raccogliamo i risultati
        // Uniamo i picchi narrow e broad in un unico canale per l'emissione finale
        ch_peaks = MACS3_CHIP_NARROW.out.peaks.mix(MACS3_CHIP_BROAD.out.peaks)
        
        // Uniamo le versioni dei software
        ch_versions = ch_versions.mix(
            MACS3_CHIP_NARROW.out.versions, 
            MACS3_CHIP_BROAD.out.versions
        )
    }

    emit:
    bam      = PICARD_MARKDUPLICATES.out.bam
    bai      = PICARD_MARKDUPLICATES.out.bai
    peaks    = ch_peaks
    versions = ch_versions
}
