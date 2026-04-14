process BOWTIE2 {
    tag "$meta.id"
    label 'process_high'
    // Manteniamo il tuo container Docker
    container 'staphb/bowtie2:2.4.4'

    input:
    tuple val(meta) , path(reads)
    tuple val(meta2), path(index)
    val   save_unaligned
    val   sort_bam

    output:
    tuple val(meta), path("*.bam")        , emit: bam     , optional:true
    tuple val(meta), path("*.log")        , emit: log
    tuple val(meta), path("*fastq.gz")    , emit: fastq   , optional:true
    path  "versions.yml"                  , emit: versions

    script:
    // Estrazione parametri NF-CORE style
    def args = task.ext.args ?: '--very-sensitive -X 2000 --no-mixed --no-discordant'
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Gestione Read Groups (Essenziale per evitare il passaggio manuale "Corrected")
    def rg_id = "${prefix}"
    def rg_sm = "${prefix}"
    def rg_pl = "ILLUMINA"
    def rg_lb = "lib1"

    def unaligned = ""
    def reads_args = ""
    if (meta.single_end) {
        unaligned = save_unaligned ? "--un-gz ${prefix}.unmapped.fastq.gz" : ""
        reads_args = "-U ${reads}"
    } else {
        unaligned = save_unaligned ? "--un-conc-gz ${prefix}.unmapped.fastq.gz" : ""
        reads_args = "-1 ${reads[0]} -2 ${reads[1]}"
    }

    def samtools_command = sort_bam ? 'sort' : 'view'
    
    """
    # Ricerca indice (Logica NF-CORE)
    INDEX=`find -L ./ -name "*.1.bt2" | sed "s/\\.1\\.bt2\$//"`
    [ -z "\$INDEX" ] && INDEX=`find -L ./ -name "*.1.bt2l" | sed "s/\\.1\\.bt2l\$//"`

    bowtie2 \\
        -x \$INDEX \\
        $reads_args \\
        --threads $task.cpus \\
        --rg-id $rg_id \\
        --rg "SM:$rg_sm" --rg "PL:$rg_pl" --rg "LB:$rg_lb" \\
        $unaligned \\
        $args \\
        2> >(tee ${prefix}.bowtie2.log >&2) \\
        | samtools $samtools_command $args2 --threads $task.cpus -o ${prefix}.bam -

    # Rinominazione file non mappati (se presenti)
    if [ -f ${prefix}.unmapped.fastq.1.gz ]; then
        mv ${prefix}.unmapped.fastq.1.gz ${prefix}.unmapped_1.fastq.gz
    fi
    if [ -f ${prefix}.unmapped.fastq.2.gz ]; then
        mv ${prefix}.unmapped.fastq.2.gz ${prefix}.unmapped_2.fastq.gz
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
