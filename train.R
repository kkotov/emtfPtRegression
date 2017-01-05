#source("corr.R")
require(caret)
df <- read.csv(file="muonGunPt3_100_emtf.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==15,]
d2 <- df[df[,"mode.1."]==15,]
reduced1 <- with(d1,data.frame(1/muPtGen, pt.0., muEtaGen, dPhi12.0., dPhi23.0., dPhi34.0., dTheta12.0., dTheta23.0., dTheta34.0., as.factor(clct1.0.), as.factor(clct2.0.), as.factor(clct3.0.), as.factor(clct4.0.), as.factor(fr1.0.), as.factor(fr2.0.), as.factor(fr3.0.), as.factor(fr4.0.)))
reduced2 <- with(d2,data.frame(1/muPtGen, pt.1., muEtaGen, dPhi12.1., dPhi23.1., dPhi34.1., dTheta12.1., dTheta23.1., dTheta34.1., as.factor(clct1.1.), as.factor(clct2.1.), as.factor(clct3.1.), as.factor(clct4.1.), as.factor(fr1.1.), as.factor(fr2.1.), as.factor(fr3.1.), as.factor(fr4.1.)))
colnames(reduced1) <- c("muPtGenInv", "ptTrg", "muEtaGen", "dPhi12", "dPhi23", "dPhi34", "dTheta12", "dTheta23", "dTheta34", "clct1", "clct2", "clct3", "clct4", "fr1", "fr2", "fr3", "fr4")
colnames(reduced2) <- c("muPtGenInv", "ptTrg", "muEtaGen", "dPhi12", "dPhi23", "dPhi34", "dTheta12", "dTheta23", "dTheta34", "clct1", "clct2", "clct3", "clct4", "fr1", "fr2", "fr3", "fr4")
reduced <- rbind(reduced1,reduced2)
part <- createDataPartition(y=reduced$muPtGen, p=0.75, list=F)
trainSet <- reduced[part,]
testSet <- reduced[-part,]
POI <- which(colnames(reduced)=="muPtGenInv")

modelFit <- ranger(muPtGenInv ~ dPhi12+dPhi23+dPhi34+dTheta12+dTheta23+dTheta34+clct1+clct2+clct3+clct4+fr1+fr2+fr3+fr4, data=trainSet)
#modelFit <- train(muPtGenInv ~ dPhi12+dPhi23+dPhi34+dTheta12+dTheta23+dTheta34+clct1+clct2+clct3+clct4+fr1+fr2+fr3+fr4, method="rf", data=trainSet, trControl=trainControl(method="cv",number=10,verboseIter=T))

# evaluate performance
print( RMSE(1/testSet[,POI], 1/predict(modelFit,testSet[,-POI])$predictions) )
print( RMSE(1/testSet[,POI], testSet[,"ptTrg"]) )
print( R2(1/testSet[,POI], 1/predict(modelFit,testSet[,-POI])$predictions ) )
print( R2(1/testSet[,POI], testSet[,"ptTrg"]) ) # 

### Try out neural networks
#fitNNet1  <- avNNet(muPtGenInv ~ dPhi12+dPhi23+dPhi34+dTheta12+dTheta23+dTheta34+clct1+clct2+clct3+clct4+fr, data=trainSet, repeats=25, size=20, decay=0.1, linout=T)
#R2(predict(fitNNet1, testSet[,-POI]) , testSet[,POI]) # 0.7509675968 
#
#require(neuralnet)
#fitNNet2  <- neuralnet(muPtGenInv ~ dPhi12+dPhi23+dPhi34+dTheta12+dTheta23+dTheta34+clct1+clct2+clct3+clct4+fr, data=trainSet, rep=10, hidden=c(30,10), linear.output=F)
#R2(compute(fitNNet2,testSet[,c(-POI,-2)])$net.result , testSet[,POI]) # 0.7422718741 so low!
#
## standardizing? 
##prepTrain <- preProcess(trainTrain[,2:26], method=c('center','scale')) # c('BoxCox')

