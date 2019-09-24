#!/usr/bin/env bash
set -euxo pipefail

NUM_CORES="$(nproc --all)"
MIN_READ_LEN=500
HEADCROP=50
PILEUP_DEPTH=500
PLOIDY=1
MIN_BQ=8

# going to leave these files untouched - copy into a new dir
AD=$1
PL=$2
INPUT_DIR_ARG=${3:-"/data"}
REF_SEQ_ARG=${4:-"/ref.fa"}

INPUT_DIR='outputs'

# # the file into which we'll list out input files
INPUT_FNAMES="INPUT_FNAMES.txt"

REF_SEQ=$(basename "$REF_SEQ_ARG")

#### Step 1: Preprocess:
# Setup the environment and make samtools indexes for reference files
mkdir -p "$INPUT_DIR"
cp "$INPUT_DIR_ARG"/*fastq "$INPUT_DIR" && cp "$REF_SEQ_ARG" "$INPUT_DIR"

cd $INPUT_DIR

# create fai file from reference sequence
samtools faidx "$REF_SEQ"
cat "$REF_SEQ.fai" | awk '{print $1 "\t" "0" "\t" $2}' > "$REF_SEQ.genome"
cat "$REF_SEQ".genome

# create an index of the ref seq
minimap2 -d "$REF_SEQ".mmi "$REF_SEQ"

# list dir, only want thing that are fq and not trimmed

ls -lt  | awk '{print $(NF)}' | grep 'fastq$' | grep -v 'trimmed' | sort > $INPUT_FNAMES
echo $INPUT_FNAMES

while read line
do
    echo "$line"
    #### Step 2: Filter reads with Nanofilt. Filter out low quality reads and trim the left end
    cat $line | NanoFilt -q $NUM_CORES -l $MIN_READ_LEN --headcrop $HEADCROP > ${line}.trimmed.fastq
    ################################

    #### Step 3: Map reads to reference genomes with minimap2, then make bam file
    minimap2 -ax map-ont $REF_SEQ.mmi "${line}".trimmed.fastq > "${line}".tr.sam
    samtools view -b -T $REF_SEQ "${line}".tr.sam -o "${line}".tr.bam
    samtools sort ${line}.tr.bam > ${line}.sorted.tr.bam
    samtools index ${line}.sorted.tr.bam
    ################################

    #### Step 4: Call and filter variants
    bcftools mpileup --no-BAQ --min-BQ $MIN_BQ -a AD -d $PILEUP_DEPTH -Ou -f $REF_SEQ ${line}.sorted.tr.bam -o ${line}.sorted.tr.raw.vcf
    bcftools call -c --ploidy $PLOIDY -Oz -o "${line}.sorted.tr.called.vcf.gz" "${line}.sorted.tr.raw.vcf"
    tabix -f "${line}.sorted.tr.called.vcf.gz"
    ################################

    #### Step 5: Get bedgraph coverage and plot using R. Also prepare masked bedgraph for use in consensus.
    # note: bcftools consensus needs a 1-based bed file, therefore I am adding 1 to the mask file below
    bedtools genomecov -ibam "${line}".sorted.tr.bam -bga >  "${line}".sorted.tr.bg
    bedtools genomecov -ibam "${line}".sorted.tr.bam -bga | grep -w 0$ | awk '{print $1 "\t" $2+1 "\t" $3+1}'>  "${line}".sorted.mask.bg
    awk -v var="${line}" '{print var "\t" $2 "\t" $3 "\t" $4}' < "${line}".sorted.tr.bg | sed 's/\.fastq//g' > "${line}".preplot.txt
    ################################
done <"$INPUT_FNAMES"

# note: the consensus was generated with the first allele.  If IUPAC names are needed, bcftools consensus should have the option "-I"
ls -l *sorted.tr.called.vcf.gz | awk '{print $NF}' > input_for_merge_called.txt
bcftools merge -l input_for_merge_called.txt -m all > all_variants.called.vcf.txt
head all_variants.called.vcf.txt

# filter the merged file.  Allow for modifying the filter.
# option 1: get variants with allele depth in any sample greater than 30.  The star applies to any sample. The ":1" refers to the alternate allele.
cat all_variants.called.vcf.txt | bcftools view --include 'FORMAT/AD[*:1] > 30 && FORMAT/PL>60' > all_variants.filtered_30-60.vcf
cat all_variants.called.vcf.txt | bcftools view --include 'FORMAT/AD[*:1] > 10 && FORMAT/PL>20' > all_variants.filtered_10-20.vcf
cat all_variants.called.vcf.txt | bcftools view --include "FORMAT/AD[*:1] > $AD && FORMAT/PL>$PL" > all_variants.filtered_$AD-$PL.vcf



cat *preplot.txt > preplot_ggplot.txt

# run the R plot stuff

cd ..
./plot_cvg.R

cd $INPUT_DIR

################################################################################################
#### Step 6: Create a bedfile with coordinates of zero coverage and use it to mask the reference genome
################################################################################################

# filter variants for each file, then create a consensus with the filtered vcf that can be aligned using mafft
# note that the consensus will be based on the stricter vcf (30AD, 60PL)
while read line
do
    bcftools view --include 'FORMAT/AD[*:1] > 30 && FORMAT/PL>60' < "${line}".sorted.tr.called.vcf.gz > "${line}".single.filtered_30-60.vcf
    bgzip -f "${line}".single.filtered_30-60.vcf
    tabix "${line}".single.filtered_30-60.vcf.gz
    bcftools consensus -m "${line}".sorted.mask.bg -f $REF_SEQ "${line}".single.filtered_30-60.vcf.gz | sed "s/>/>${line} /g" > "${line}".sorted.tr.masked.30-60.vcf.fa
   echo "$line"
done < "$INPUT_FNAMES"

### make a multifasta with all consensus sequences and also including the reference genome
rm -f all.sorted.tr.masked.30-60.vcf.fa
cat *sorted.tr.masked.30-60.vcf.fa > all.sorted.tr.masked.vcf.fa
cat all.sorted.tr.masked.vcf.fa $REF_SEQ > all.sorted.tr.masked_and_ref.fasta

# Clustal ouptput format
mafft  --localpair  --maxiterate 16 --clustalout --reorder "all.sorted.tr.masked_and_ref.fasta" > "all.sorted.tr.masked_and_ref.aln"
# (optional) Phylip Output format
mafft  --localpair  --maxiterate 16 --phylipout --reorder "all.sorted.tr.masked_and_ref.fasta" > "all.sorted.tr.masked_and_ref.phylip"

status=$?

if test $status -eq 0
then
    echo "Pipeline exited normally".
else
	  echo "Pipeline failed to complete properly, see above."
fi
