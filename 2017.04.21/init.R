mode_inv <- 15
mode = c(0, 0, 12, 0, 10, 5, 14, 0, 9, 5, 13, 3, 11, 7, 15)
df <- read.csv(file="../../pt/SingleMu_Pt1To1000_FlatRandomOneOverPt_plusRPC_2.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
d2 <- df[df[,"mode.1."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]
colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)
d <- rbind(d1,d2)

require(ranger)

vars <- with(d,data.frame( 1/muPtGen,
                           theta_i,
                           factor(ring1,levels=c(1,2,4)),
                           pt,
                           mypt,
                           dPhi12,
                           dPhi13,
                           dPhi14,
                           dPhi23,
                           dPhi24,
                           dPhi34,
                           dTheta12,
                           dTheta13,
                           dTheta14,
                           dTheta23,
                           dTheta24,
                           dTheta34,
                           factor(clct1,levels=c(2,3,4,5,6,7,8,9,10)),
                           factor(clct2,levels=c(2,3,4,5,6,7,8,9,10)),
                           factor(clct3,levels=c(2,3,4,5,6,7,8,9,10)),
                           factor(clct4,levels=c(2,3,4,5,6,7,8,9,10)),
                           factor(fr1,levels=c(0,1)),
                           factor(fr2,levels=c(0,1)),
                           factor(fr3,levels=c(0,1)),
                           factor(fr4,levels=c(0,1))
                           )
            )
predictors <- c("dPhi12", "dPhi13", "dPhi14", "dPhi23", "dPhi24", "dPhi34", "dTheta12", "dTheta13", "dTheta14", "dTheta23", "dTheta24", "dTheta34", "clct1", "clct2", "clct3", "clct4", "fr1", "fr2", "fr3", "fr4")
colnames(vars) <- c("muPtGenInv", "theta", "ring1", "ptTrg", "mypt", predictors )
predictors <- c("theta", "ring1", predictors)

vars$zero <- 0
vars$one  <- 1

set.seed(1)

part <- sample(seq(nrow(vars)), as.integer(nrow(vars)*0.75), replace=F)
trainSet <- vars[part,]
testSet <- vars[-part,]
POI <- which(colnames(vars)=="muPtGenInv")

f <- as.formula(paste("muPtGenInv ~ ", paste(predictors, collapse= "+")))

rateShapeBinned = c(1,1/seq(2,200,0.5)^3)
binning = seq(2,200,0.5)
nBins <- length(binning)

##############################

source("../utils.R")

vars7 <- with(vars,data.frame( muPtGenInv,
                               ptTrg,
                           msb(theta + c(0,6,6,0)[as.integer(as.character(ring1))],7,2),
                           msb(abs(sat(dPhi12,9)),9,2),
                           msb(abs(sat(dPhi23,7)),7,2),
                           msb(abs(sat(dPhi34,7)),7,2),
                           as.factor(ifelse(dPhi23*dPhi12>=0,zero,one)),
                           as.factor(ifelse(dPhi34*dPhi12>=0,zero,one)),
                           msb(abs(sat(dPhi12,9)),9,2) + ifelse(dPhi23*dPhi12>=0,one,-one)*msb(abs(sat(dPhi23,7)),7,2), # analogous to dPhi13
                           msb(abs(sat(dPhi12,9)),9,2) + ifelse(dPhi23*dPhi12>=0,one,-one)*msb(abs(sat(dPhi23,7)),7,2) + ifelse(dPhi34*dPhi12>=0,one,-one)*msb(abs(sat(dPhi34,7)),7,2),
                           msb(abs(sat(dPhi23,7)),7,2) + ifelse(dPhi34*dPhi12>=0,one,-one)*msb(abs(sat(dPhi34,7)),7,2), # analogous to dPhi24
                           abs(sat(dTheta14,2)),
                           c(0,0,0,0,1,1,2,2,3,3,3,0,0,0,0,0)[bitwAnd(as.integer(as.character(clct1)),0xF)+1],
                           fr1
                             )
         )

predictors4 <- c("dPhi12", "dPhi23", "dPhi34", "sPhi123", "sPhi134", "dPhi13", "dPhi14", "dPhi24", "dTheta14", "clct1", "fr1")

colnames(vars7) <- c("muPtGenInv", "ptTrg", predictors4)

set.seed(1)

trainSet7 <- vars7[part,]
testSet7 <- vars7[-part,]

###############################

require(h2o)

h2o.init(nthreads=-1)

df <- as.h2o(vars7)

splits <- h2o.splitFrame(df, c(0.6,0.2), seed=1234)
train  <- h2o.assign(splits[[1]], "train.hex") # 60%
valid  <- h2o.assign(splits[[2]], "valid.hex") # 20%
test   <- h2o.assign(splits[[3]], "test.hex")  # 20%

model <- h2o.deeplearning(x=c(3:14), y=1, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(80,80), epochs = 500)

pred <- as.data.frame( h2o.predict(model,test) )

mse <- sum( (test$muPtGenInv - pred$predict)^2)

