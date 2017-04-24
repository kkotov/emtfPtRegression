require(h2o)
# init from 2017.03.17
train.hex <- as.h2o(trainSet)
test.hex <- as.h2o(testSet)
model <- h2o.randomForest(x=c(2,3,6:25), y=1, training_frame = train.hex, validation_frame = test.hex, mtries = 5, sample_rate = 0.5, ntree = 200)
pred <- h2o.predict(model,test.hex)
p <- as.data.frame(pred)

rateShapeBinned = c(1,1/seq(2,200,0.5)^3)
binning = seq(2,200,0.5)
nBins <- length(binning)

source("../metrics.R")

testSet$res <- 1/p$predict
testSet$trueBin <- sapply(1/testSet$muPtGenInv, findBin, binning)
pSpec <- aggregate(testSet, by=list(bin=testSet$trueBin), function(x) x )
pSpec$count <- sapply(pSpec$res,length)
myModelCount   <- t(sapply(pSpec$res,  function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
referenceCount <- t(sapply(pSpec$ptTrg,function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
myModelTurnOn   <- myModelCount   / pSpec$count
referenceTurnOn <- referenceCount / pSpec$count

require(ggplot2)
#tt <- turnOns(rateShapeBinned = rateShapeBinned, myModelTurnOn = myModelTurnOn, referenceTurnOn = referenceTurnOn, binning = binning, refScale = 1.43)
roc <- rocMetric(rateShapeBinned = rateShapeBinned, myModelTurnOn = myModelTurnOn, referenceTurnOn = referenceTurnOn, binning = binning, refScale = 1.43)
roc[["rocPlot"]]

model2 <- h2o.deeplearning(x=c(2,3,6:25), y=1, training_frame = train.hex, validation_frame = test.hex, #activation = "RectifierWithDropout",
                input_dropout_ratio = 0.2, hidden_dropout_ratios = c(0.5,0.5), hidden = c(80,80), epochs = 500)

pred2 <- h2o.predict(model2,test.hex)
p2 <- as.data.frame(pred2)
testSet$res2 <- 1/p2$predict
pSpec2 <- aggregate(testSet, by=list(bin=testSet$trueBin), function(x) x )
pSpec2$count <- sapply(pSpec2$res2,length)
myModelCount   <- t(sapply(pSpec2$res2, function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
referenceCount <- t(sapply(pSpec2$ptTrg,function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
myModelTurnOn   <- myModelCount   / pSpec2$count
referenceTurnOn <- referenceCount / pSpec2$count

roc2 <- rocMetric(rateShapeBinned = rateShapeBinned, myModelTurnOn = myModelTurnOn, referenceTurnOn = referenceTurnOn, binning = binning, refScale = 1.43)
roc2[["rocPlot"]]

results <- with(testSet,data.frame( ptTrue = 1/muPtGenInv, refPt = ptTrg, myPt = res2 ))
source("../residuals.R")
plot.residuals(results)
