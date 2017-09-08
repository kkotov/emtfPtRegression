require(ggplot2)
source("../metrics.R")

if( !file.exists("three.csv") ){
  system("echo \"muPtGen\",\"theta\",\"st1_ring2\",\"dPhi12\",\"dPhi13\",\"dPhi14\",\"dPhi23\",\"dPhi24\",\"dPhi34\",\"dTheta12\",\"dTheta13\",\"dTheta14\",\"dTheta23\",\"dTheta24\",\"dTheta34\",\"dPhiS4\",\"dPhiS4A\",\"dPhiS3\",\"dPhiS3A\",\"clct1\",\"clct2\",\"clct3\",\"clct4\",\"fr1\",\"fr2\",\"fr3\",\"fr4\",\"rpc1\",\"rpc2\",\"rpc3\",\"rpc4\",\"ptXML\",\"myPt\",\"row.names\" > three.csv")
  system("cat two.csv | sed -e 's|(int)||g' -e 's|(float)||g' -e 's| $||g' -e 's| |,|g' >> three.csv")
}

rateShapeBinned = c(1,1/seq(2,200,0.5)^3)
binning = seq(2,200,0.5)
nBins <- length(binning)

df <- read.csv("three.csv",sep=',',header=T,row.names=34)

testSet <- data.frame(res = exp(df$myPt), muPtGen = exp(df$muPtGen), ptTrg = exp(df$ptXML))
testSet$trueBin <- sapply(testSet$muPtGen, findBin, binning)
pSpec <- aggregate(testSet, by=list(bin=testSet$trueBin), function(x) x )
pSpec$count <- sapply(pSpec$res,length)

myModelCount   <- t(sapply(pSpec$res,  function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
referenceCount <- t(sapply(pSpec$ptTrg,function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
myModelTurnOn   <- myModelCount   / pSpec$count
referenceTurnOn <- referenceCount / pSpec$count

roc <- rocMetric(rateShapeBinned = rateShapeBinned, myModelTurnOn = myModelTurnOn, referenceTurnOn = referenceTurnOn, binning = binning, refScale = 1)
roc[["rocPlot"]]

#ggplot(data=subset(testSet,muPtGen<128),aes(x=(res-muPtGen)/muPtGen)) + geom_histogram(breaks=seq(-1,1,0.01))
