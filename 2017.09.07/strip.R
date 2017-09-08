df <- read.csv(file="../../pt/oldSim.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==15, c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
d2 <- df[df[,"mode.1."]==15, c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]
colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)
d <- rbind(d1,d2)
#require(ggplot2)
#d2 <- data.frame(eta=c(d[,6],d[,7]), type=factor(c(rep(1,nrow(d)),rep(2,nrow(d)))))
#colnames(d2)
#ggplot(d2,aes(x=eta,group=type,color=type)) + geom_histogram(data=subset(d2,type==1),fill="red",alpha=0.2) + geom_histogram(data=subset(d2,type==2),fill="blue",alpha=0.2)
skim <- d[,c(5,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,4)]
write.csv(file="one.csv",skim, row.names=FALSE)
colnames(skim)
require(ranger)
skim[,"muPtGenInv"] <- 1./skim[,"muPtGen"]
modelFit <- ranger("muPtGenInv ~ theta + dPhi12 + dPhi13 + dPhi14 + dPhi23 + dPhi24 + dPhi34", data=trainSet, importance="impurity")
modelFit <- ranger("muPtGenInv ~ theta + dPhi12 + dPhi13 + dPhi14 + dPhi23 + dPhi24 + dPhi34", data=skim[seq(1,nrow(skim),2),], importance="impurity")
testSet <- skim[seq(2,nrow(skim),2),]
m <- mean(testSet$muPtGenInv - predict(modelFit,testSet)$prediction)
sdev <- sd(testSet$muPtGenInv - predict(modelFit,testSet)$prediction)
m
sdev
