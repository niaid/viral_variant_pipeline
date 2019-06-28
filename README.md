# viral_variant_pipeline

This viral variant pipeline and dependancies have been packaged on a [docker](https://www.docker.com/) image  to allow it to run on your local machine. To be able to use it you will need a [dockerhub](https://hub.docker.com/) account.

## Setup 
This only needs to do be done once OR if the image has been changed and you want to run the updated version.

- Log in to docker and download the image:

```sh
docker login
# enter details
docker pull philipmac/vir_pipe
```


## Running the pipeline.

If you are running Darwin (OSX) or Linux the pipeline can be run using [this](https://github.com/niaid/viral_variant_pipeline/blob/master/vir_call.sh) script. 
Set the following environment variables:

- The path to the directory containing your fastq inputs: `INPUT_DIR`.
- The path to the sinlge reference fasta file which the fastq files will be compared to: `REF_SEQ`.
- The path to the directory that will be created for the outputs: `OUTPUTS`.


```sh
export INPUT_DIR=/home/macmenaminpe/data/test_chikungunya_fq/
export REF_SEQ=/home/macmenaminpe/data/ref/GCF_000854045.1_ViralProj14998_genomic.fna
export OUTPUTS=/home/macmenaminpe/test_outputs_dir
```

Run the pipeline (In this example I'm setting AD to 10 and PL to 20):

```sh
run_pipe.sh -a 10 -p 20
```

Look at your results:
```sh
ls $OUTPUTS
```

