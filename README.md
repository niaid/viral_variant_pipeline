# viral_variant_pipeline
Get the container onto your machine - only need to do this once / if the container has been changed.

Log in to docker hub:

`docker login` 

Pull container:

`docker pull philipmac/vir_pipe`

Set up your environment:

Set INPUT_DIR as the name of the directory where the data to be analysed is:

`export INPUT_DIR=~/data/test_chikungunya_fq/`

Set REF_SEQ to the reference sequence you want to compare against. 

`export REF_SEQ=~/data/ref/GCF_000854045.1_ViralProj14998_genomic.fna`

Set OUTPUTS to where you'd like your outputs to be put. (Make sure this directory exists!)

`export OUTPUTS=~/test_outputs_dir`


Run the pipeline (In this example I'm setting AD to 10 and PL to 20):

`docker run --rm -v $INPUT_DIR:/data -v $REF_SEQ:/ref.fa -v $OUTPUTS:/outputs philipmac:vir_pipe bash -c "/h2.sh 10 20 > outputs/log.txt 2>&1"`

Look at your results:

`ls $OUTPUTS`

