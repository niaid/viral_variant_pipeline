#!/usr/bin/Rscript


library(ggplot2)
d <-read.table("outputs/preplot_ggplot.txt",sep="",header=F)
colnames(d)<-c("ID","start","end","depth")
cov <- ggplot(d, aes(x=start, y=depth)) + geom_rect(aes(xmin=start,xmax=end,ymin=0,ymax=depth)) + ggtitle("Coverage") +
facet_wrap(~ ID, ncol=1)
ggsave("outputs/all_coverage.pdf", width = 8, height = 20)
quit()

