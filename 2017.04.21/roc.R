source("../metrics.R")
require(ggplot2)

roc <- function(testSet,p){

    testSet$res <- 1/p$predict
    testSet$trueBin <- sapply(1/testSet$muPtGenInv, findBin, binning)
    pSpec <- aggregate(testSet, by=list(bin=testSet$trueBin), function(x) x )
    pSpec$count <- sapply(pSpec$res,length)
    myModelCount   <- t(sapply(pSpec$res,  function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
    referenceCount <- t(sapply(pSpec$ptTrg,function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
    myModelTurnOn   <- myModelCount   / pSpec$count
    referenceTurnOn <- referenceCount / pSpec$count

    roc <- rocMetric(rateShapeBinned = rateShapeBinned, myModelTurnOn = myModelTurnOn, referenceTurnOn = referenceTurnOn, binning = binning, refScale = 1.43)
    roc[["rocPlot"]]
}
