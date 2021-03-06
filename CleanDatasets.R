library(sqldf)
#usage CleanDatasets.R type oldir annodir newdir snpcut genecut paramfile JobsizeInGB
oargs <- commandArgs(trailingOnly=T)
args <- list()

args$type <- oargs[[1]]
args$oldir <- oargs[[2]]
args$annodir <- oargs[[3]]
args$newdir <- oargs[[4]]
args$snpcut <- as.numeric(oargs[[5]])
args$genecut <- as.numeric(oargs[[6]])
args$paramfile <- oargs[[7]]
args$GB <- as.integer(oargs[[8]])

args$SNPfile <- paste0(args$oldir,"snp_",args$type,".txt")
args$GENEfile <- paste0(args$oldir,"seq_",args$type,".txt")

args$SNPanno <- paste0(args$annodir,"snpanno.txt")
args$Geneanno <- paste0(args$annodir,"geneanno.txt")

args$NewSNPfile <- paste0(args$newdir,"snp_",args$type,".txt")
args$NewGENEfile <- paste0(args$newdir,"seq_",args$type,".txt")
args$h5file <- paste0(args$newdir,"snpgenemat_",args$type,".h5")
args$annofile <- paste0(args$annodir,"snpgeneanno.h5")


args$eqtlfile <- paste0(args$newdir,args$type,"_eqtl")
args$statfile <- paste0(args$newdir,args$type,"stat")

paste0(args)

paste0("Reading in snp file ",args$SNPfile)
snpdata <- read.csv.sql(args$SNPfile,sep="\t",header=T,eol="\n")
paste0("Reading in gene file ",args$GENEfile)
genedata <- read.csv.sql(args$GENEfile,sep="\t",header=T,eol="\n")

paste0("Reading in SNP anno ",args$SNPanno)
snpanno <- read.csv.sql(args$SNPanno,sep="\t",header=F,eol="\n")
paste0("Reading in gene anno ",args$Geneanno)
geneanno <- read.csv.sql(args$Geneanno,sep="\t",header=F,eol="\n")


snpdata <- snpdata[!duplicated(snpdata[,1]),]
genedata <- genedata[!duplicated(genedata[,1]),]

rownames(snpdata) <- snpdata[,1]
rownames(genedata) <- genedata[,1]

snpdata <- snpdata[,-1]
genedata <- genedata[,-1]


colnames(snpdata) <- substr(colnames(snpdata),1,12)
paste0("first snpcols: ",Reduce(paste,head(colnames(snpdata))))
colnames(genedata) <- substr(colnames(genedata),1,12)
paste0("first genecols: ",Reduce(paste,head(colnames(genedata))))

paste0("Subsetting snpdata")
snpdata <-  snpdata[,colnames(snpdata) %in% colnames(genedata)]
paste0("subsetting genedata")
genedata <- genedata[,colnames(snpdata)]

snpanno <- snpanno[snpanno[,1] %in% rownames(snpdata),]
geneanno <- geneanno[geneanno[,1] %in% rownames(genedata),]

snpdata <- snpdata[snpanno[,1],]
geneanno <- genedata[geneanno[,1],]

snpcount <- apply(snpdata,1,function(x)sum(sort(tabulate(x+1),decreasing=T)[-1]))
snpcount <- snpcount/ncol(snpdata)

snpdata <- snpdata[snpcount>args$snpcut,]

genecount <- apply(genedata,1,function(x)sum(x>0))
genecount <- genecount/ncol(genedata);

genedata <- genedata[genecount>args$genecut,]

bsi <- ceiling(ncol(genedata)*log10(ncol(genedata)))
snpgenesize <- ceiling(sqrt((1024^3*args$GB)/(bsi*8)))

snpgenesize <- floor(snpgenesize/64)*64
snptotal <- nrow(snpdata)
snpchunks <- ceiling(snptotal/snpgenesize)
genetotal <- nrow(genedata)
genechunks <- ceiling(genetotal/snpgenesize)

params <- c(snpfile=args$NewSNPfile,
            genefile=args$NewGENEfile,
            genecut=args$genecut,
            snpcut=args$snpcut,
            h5file=args$h5file,
            annofile=args$annofile,
            progfile=args$statfile,
            eqtlfile=args$eqtlfile,
            snpchunks=snpchunks,
            genechunks=genechunks,
            snptotal=snptotal,
            genetotal=genetotal,
            snpsize=snpgenesize,
            genesize=snpgenesize,
            casetotal=ncol(genedata),
            snpabstotal=906598,
            geneabstotal=20501,
            bsi=bsi,
            t_thresh=3.5,
            cisdist="1000000")

aparams <- paste(names(params),params,sep="=")

write(aparams,file=args$paramfile,sep="\n")


                  

write.table(snpdata,args$NewSNPfile,sep="\t",col.names=T,row.names=T,quote=F)
write.table(genedata,args$NewGENEfile,sep="\t",col.names=T,row.names=T,quote=F)


