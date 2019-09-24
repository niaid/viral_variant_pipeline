FROM debian:buster

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
      build-essential \
      samtools \
      minimap2 \
      tabix \
      bcftools \
      bedtools \
      mafft \
      r-base \
      r-cran-ggplot2 \
      python3-pip && \
    pip3 install NanoFilt && \
    rm -rf /root/.cache &&\
    apt autoremove --purge -y \
      build-essential \
      gfortran &&\
    rm -rf /var/lib/apt/lists/* 

COPY plot_cvg.R /
COPY vir_call.sh /
