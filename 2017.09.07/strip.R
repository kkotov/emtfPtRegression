df <- read.csv(file="../../../oldSim.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==15, c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
d2 <- df[df[,"mode.1."]==15, c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]
colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)
d <- rbind(d1,d2)

skim <- d[,c(5,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,4)]
predictors <- c("theta", "st1_ring2", "dPhi12", "dPhi13", "dPhi14", "dPhi23", "dPhi24", "dPhi34", "dTheta14", "dPhiS4", "dPhiS4A", "dPhiS3", "dPhiS3A", "clct1", "fr1", "rpc1", "rpc2", "rpc3", "rpc4")
skim[,"muPtGenInv"] <- 1./skim[,"muPtGen"]

set.seed(333)
# Define a training sample
skim$trainIdx <- rbinom(nrow(skim), 1, 0.5)

# Reweighting index
weighted <- skim[sample(seq_len(nrow(skim)), size=1000000, replace=T, prob=skim$muPtGenInv**2),]

require(ranger)
f <- as.formula(paste("muPtGenInv ~ ", paste(predictors, collapse= "+")))
modelFit <- ranger(f, data=subset(weighted, trainIdx==1), importance="impurity")
weighted$ranger <- signif(1./predict(modelFit,weighted)$prediction,digits=6)

testSet <- subset(weighted, trainIdx==0)
m <- mean(testSet$muPtGenInv - predict(modelFit,testSet)$prediction)
sdev <- sd(testSet$muPtGenInv - predict(modelFit,testSet)$prediction)
print(paste("mean",m," dev",sdev))

require(gbm)
modelFit2 <- gbm(f, data=subset(weighted, trainIdx==1), distribution="gaussian", n.trees=1000, shrinkage=0.001, interaction.depth=4)
weighted$gbm <- signif(1./predict(modelFit2,weighted,n.trees=1000),digits=6)

write.csv(file="one.csv", weighted[,-which(colnames(skim)=="muPtGenInv")], row.names=FALSE)
colnames(skim)
