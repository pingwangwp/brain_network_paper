options(stringsAsFactors = F)
library(sva)
library(caret)

#functions####
# Median+/-6MAD
outlier<-function(x,alpha=6){ #Median+/-6MAD
  x[x<median(x)-alpha*mad(x)|x>median(x)+alpha*mad(x)]<-NA
  return(x)
}
# inverse-normal transformation
INT<-function(x){
  return(qnorm((rank(x,na.last="keep")-0.5)/sum(!is.na(x))))
}

#raw data to matched samples
pheno4matchedsamples<-function(inputfile){
        print("loading data...")
        data<-read.delim(inputfile,row.names=1)
        print("matching samples...")
        data<-data[match(sample,row.names(data)),]
	return(data)
}

#matched samples to MAD
pheno4MAD<-function(data){
  print("setting outlier...")
  data.outlier<-apply(data,2,outlier)
  return(data.outlier)
}

#match MAD in the corresponding DTI & rfMRI traits
matchMAD<-function(data1,data2){
  if(any(!colnames(data1)==colnames(data2))){
    stop("Error: unmatched trait.")
  }
  if(any(!rownames(data1)==rownames(data2))){
    stop("Error: unmatched sample.")
  }
  cat("Before MAD match, ",table(is.na(data1))['TRUE']," NAs in data1; ",table(is.na(data2))['TRUE']," NAs in data2.\n")
  for (i in 1:ncol(data1)){
    tmp<-apply(cbind(data1[,i],data2[,i]),1,function(x) any(is.na(x)))
    data1[tmp,i]<-NA
    data2[tmp,i]<-NA
  }
  if(any(!(is.na(data1)==is.na(data2)))){
    stop("Error: unmatched MAD.")
  }
  cat("After MAD match, ",table(is.na(data1))['TRUE']," NAs in data1; ",table(is.na(data2))['TRUE']," NAs in data2.\n")
  return(list(data1=data1,data2=data2))
}

#MAD to bgenie
pheno4bgenie<-function(data.outlier,outputfile.ComBat,outputfile.bgenie){
        print("ComBating...")
        data.outlier.ComBat<-t(ComBat(t(data.outlier),batch = site$site))
        write.table(data.frame(ID=row.names(data.outlier.ComBat),data.outlier.ComBat),
                    outputfile.ComBat,
                    append = F,quote = F,sep = "\t",row.names = F)
        print("Guassing...")
        data.outlier.ComBat.guassian<-apply(data.frame(data.outlier.ComBat),2,INT)
        print("Writing...")
        write.table(data.outlier.ComBat.guassian,outputfile.bgenie,
                    na='-999',append = F,quote = F,sep = "\t",row.names = F)
}

#sample
sample<-read.table("UKBB_samplefilter.33716.sample",header=T)
sample<-sample[-1,1]

#Image Site
site<-read.delim("ImageSite")
colnames(site)<-c("ID","site")
site<-site[match(sample,site$ID),]

#DTItopo & rfMRItopo####
pheno.DTItopo<-pheno4matchedsamples("UKBB_DTI_AAL90_toporesults_all.33716.txt")
pheno.rfMRItopo<-pheno4matchedsamples("UKBB_rfMRI_AAL90_toporesults_all.33716.txt")
pheno.DTItopo.MAD<-pheno4MAD(pheno.DTItopo)
pheno.rfMRItopo.MAD<-pheno4MAD(pheno.rfMRItopo)
table(is.na(pheno.DTItopo.MAD));table(is.na(pheno.rfMRItopo.MAD))
tmp<-matchMAD(pheno.DTItopo.MAD,pheno.rfMRItopo.MAD)
pheno.DTItopo.MAD<-tmp$data1
pheno.rfMRItopo.MAD<-tmp$data2
table(is.na(pheno.DTItopo.MAD));table(is.na(pheno.rfMRItopo.MAD))
rm(tmp)
pheno.DTItopo.MAD.nzv<-nearZeroVar(pheno.DTItopo.MAD);length(pheno.DTItopo.MAD.nzv)
pheno.rfMRItopo.MAD.nzv<-nearZeroVar(pheno.rfMRItopo.MAD);length(pheno.rfMRItopo.MAD.nzv)
pheno.DTItopo.MAD<-pheno.DTItopo.MAD[,-(union(pheno.DTItopo.MAD.nzv,pheno.rfMRItopo.MAD.nzv))]
pheno.rfMRItopo.MAD<-pheno.rfMRItopo.MAD[,-(union(pheno.DTItopo.MAD.nzv,pheno.rfMRItopo.MAD.nzv))]
##keep traits sample size >= 25000
samplesize.topo<-apply(pheno.DTItopo.MAD,2,function(x) length(which(!is.na(x))))
range(samplesize.topo)
samplesize.topo<-samplesize.topo[samplesize.topo>=25000]
pheno.DTItopo.MAD<-pheno.DTItopo.MAD[,names(samplesize.topo)]
pheno.rfMRItopo.MAD<-pheno.rfMRItopo.MAD[,names(samplesize.topo)]

pheno4bgenie(pheno.DTItopo.MAD,
             "UKBB_DTI_AAL90_toporesults_all.33716.Combat.txt",
             "UKBB_DTI_AAL90_toporesults_all.33716.bgenie.txt")
pheno4bgenie(pheno.rfMRItopo.MAD,
             "UKBB_rfMRI_AAL90_toporesults_all.33716.Combat.txt",
             "UKBB_rfMRI_AAL90_toporesults_all.33716.bgenie.txt")

#SC & FC####
pheno.SC<-pheno4matchedsamples("UKBB_SC.33716.SC80.txt")
pheno.FC<-pheno4matchedsamples("ukbb_fc_r.33716.SC80.txt")
#set negative functional connections as 0
if(min(pheno.FC)<0){
  pheno.FC[pheno.FC<0]<-0
}
pheno.SC.MAD<-pheno4MAD(pheno.SC)
pheno.FC.MAD<-pheno4MAD(pheno.FC)
table(is.na(pheno.SC.MAD));table(is.na(pheno.FC.MAD))
tmp<-matchMAD(pheno.SC.MAD,pheno.FC.MAD)
pheno.SC.MAD<-tmp$data1
pheno.FC.MAD<-tmp$data2
table(is.na(pheno.SC.MAD));table(is.na(pheno.FC.MAD))
rm(tmp)
pheno.SC.MAD.nzv<-nearZeroVar(pheno.SC.MAD);length(pheno.SC.MAD.nzv) #0 column没有需要去掉的trait
pheno.FC.MAD.nzv<-nearZeroVar(pheno.FC.MAD);length(pheno.FC.MAD.nzv) #0 column没有需要去掉的trait
##keep traits sample size >= 25000
samplesize.edge<-apply(pheno.SC.MAD,2,function(x) length(which(!is.na(x))))
range(samplesize.edge)
samplesize.edge<-samplesize.edge[samplesize.topo>=25000]
pheno.SC.MAD<-pheno.SC.MAD[,names(samplesize.edge)]
pheno.FC.MAD<-pheno.FC.MAD[,names(samplesize.edge)]

pheno4bgenie(pheno.SC.MAD,
             "UKBB_SC.33716.SC80.Combat.txt",
             "UKBB_SC.33716.SC80.bgenie.txt")
pheno4bgenie(pheno.FC.MAD,
             "ukbb_fc_r.33716.SC80.Combat.txt",
             "ukbb_fc_r.33716.SC80.bgenie.txt")
