require(doMC)
require(caret)
require(ranger)
require(randomForest)
# mode_inv=15 (mode=15): 1-2-3-4
# mode_inv=14 (mode=7):    2-3-4
# mode_inv=13 (mode=11): 1- -3-4
# mode_inv=12 (mode=3):      3-4
# mode_inv=11 (mode=13): 1-2- -4
# mode_inv=10 (mode=5):    2- -4
# mode_inv=9  (mode=9):  1-   -4
# mode_inv=7  (mode=14): 1-2-3
# mode_inv=6  (mode=6):    2-3
# mode_inv=5  (mode=10): 1- -3
# mode_inv=3  (mode=12): 1-2

mode = c(0, 0, 12, 0, 10, 5, 14, 0, 9, 5, 13, 3, 11, 7, 15)

df <- read.csv(file="muonGunPt3_100_emtf.csv",header=T,sep=',')

registerDoMC(3)

trainModel <- function(mode_inv, truncate=T){

    if( mode[mode_inv] == 0 ){
        print("Problem")
        return(NULL)
    }

    d1 <- df[df[,"mode.0."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
    d2 <- df[df[,"mode.1."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]

    colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
    colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)

    d <- rbind(d1,d2)

    # http://github.com/jiafulow/L1TriggerSep2016/blob/master/L1TMuonEndCap/src/EMTFPtAssignmentEngine.cc#L145-L329
    if( mode_inv == 15 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   mypt,
                                   sat(dPhi12,7),
                                   sat(dPhi23,7),
                                   sat(dPhi34,7),
                                   sat(dTheta12,2),
                                   sat(dTheta23,2),
                                   sat(dTheta34,2),
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
        predictors <- c("dPhi12", "dPhi23", "dPhi34", "dTheta12", "dTheta23", "dTheta34", "clct1", "clct2", "clct3", "clct4", "fr1", "fr2", "fr3", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", "mypt", predictors )
        if( truncate ){
            q <- address2predictors15( predictors2address15(vars) ) # this will truncate the unnecessary clct levels
            predictors <- c("dPhi12", "dPhi23", "dPhi34", "dTheta23", "clct1")
            vars[, predictors] <- q[, predictors]
        }
    } else if( mode_inv == 14 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   mypt,
                                   sat(dPhi23,10),
                                   sat(dPhi34,10),
                                   sat(dTheta23,7),
                                   sat(dTheta34,7),
                                   factor(clct2,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct3,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct4,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(fr2,levels=c(0,1)),
                                   factor(fr3,levels=c(0,1)),
                                   factor(fr4,levels=c(0,1))
                                 )
                         )
        predictors <- c("dPhi23", "dPhi34", "dTheta23", "dTheta34", "clct2", "clct3", "clct4", "fr2", "fr3", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", "mypt", predictors )
        if( truncate ){
            q <- address2predictors14( predictors2address14(vars) ) # this will truncate the unnecessary clct levels
            predictors <- c("dPhi23", "dPhi34", "clct2", "clct3", "clct4")
            vars[, predictors] <- q[, predictors]
        }
    } else if( mode_inv == 13 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   sat(dPhi13,9),
                                   sat(dPhi34,9),
                                   sat(dTheta13,7),
                                   sat(dTheta34,7),
                                   factor(clct1,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct3,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct4,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(fr1,levels=c(0,1)),
                                   factor(fr3,levels=c(0,1)),
                                   factor(fr4,levels=c(0,1))
                                 )
                         )
        predictors <- c("dPhi13", "dPhi34", "dTheta13", "dTheta34", "clct1", "clct3", "clct4", "fr1", "fr3", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
        if( truncate ){
            q <- address2predictors13( predictors2address13(vars) ) # this will truncate the unnecessary clct levels
            predictors <- c("dPhi13", "dPhi34", "clct1", "clct3", "clct4", "fr1")
            vars[, predictors] <- q[, predictors]
        }
    } else if( mode_inv == 12 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi34,
                                   dTheta34,
                                   as.factor(clct3),
                                   as.factor(clct4),
                                   as.factor(fr3),
                                   as.factor(fr4)
                                 )
                         )
        predictors <- c("dPhi34", "dTheta34", "clct3", "clct4", "fr3", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    } else if( mode_inv == 11 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi12,
                                   dPhi24,
                                   dTheta12,
                                   dTheta24,
                                   as.factor(clct1),
                                   as.factor(clct2),
                                   as.factor(clct4),
                                   as.factor(fr1),
                                   as.factor(fr2),
                                   as.factor(fr4)
                                 )
                         )
        predictors <- c("dPhi12", "dPhi24", "dTheta12", "dTheta24", "clct1", "clct2", "clct4", "fr1", "fr2", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    } else if( mode_inv == 10 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi24,
                                   dTheta24,
                                   as.factor(clct2),
                                   as.factor(clct4),
                                   as.factor(fr2),
                                   as.factor(fr4)
                                 )
                         )
        predictors <- c("dPhi24", "dTheta24", "clct2", "clct4", "fr2", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    } else if( mode_inv == 9 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi14,
                                   dTheta14,
                                   as.factor(clct1),
                                   as.factor(clct4),
                                   as.factor(fr1),
                                   as.factor(fr4)
                                 )
                         )
        predictors <- c("dPhi14", "dTheta14", "clct1", "clct4", "fr1", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    } else if( mode_inv == 7 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi12,
                                   dPhi23,
                                   dTheta12,
                                   dTheta23,
                                   as.factor(clct1),
                                   as.factor(clct2),
                                   as.factor(clct3),
                                   as.factor(fr1),
                                   as.factor(fr2),
                                   as.factor(fr3)
                                 )
                         )
        predictors <- c("dPhi12", "dPhi23", "dTheta12", "dTheta23", "clct1", "clct2", "clct3", "fr1", "fr2", "fr3")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    } else if( mode_inv == 6 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi23,
                                   dTheta23,
                                   as.factor(clct2),
                                   as.factor(clct3),
                                   as.factor(fr2),
                                   as.factor(fr3)
                                 )
                         )
        predictors <- c("dPhi23", "dTheta23", "clct2", "clct3", "fr2", "fr3")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    } else if( mode_inv == 5 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi13,
                                   dTheta13,
                                   as.factor(clct1),
                                   as.factor(clct3),
                                   as.factor(fr1),
                                   as.factor(fr3)
                                 )
                         )
        predictors <- c("dPhi13", "dTheta13", "clct1", "clct3", "fr1", "fr3")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    } else if( mode_inv == 3 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   dPhi12,
                                   dTheta12,
                                   as.factor(clct1),
                                   as.factor(clct2),
                                   as.factor(fr1),
                                   as.factor(fr2)
                                 )
                         )
        predictors <- c("dPhi12", "dTheta12", "clct1", "clct2", "fr1", "fr2")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )
    }

#    part <- createDataPartition(y=vars$muPtGenInv, p=0.75, list=F)

    set.seed(1)

    part <- sample(seq(nrow(vars)), as.integer(nrow(vars)*0.75), replace=F)
    trainSet <- vars[part,]
    testSet <- vars[-part,]
    POI <- which(colnames(vars)=="muPtGenInv")

    f <- as.formula(paste("muPtGenInv ~ ", paste(predictors, collapse= "+")))

#    modelFit <- randomForest(f, importance=T, data=trainSet) #mtry=7, 
#    modelFit <- train(f, method="rf", importance=T, data=trainSet, trControl=trainControl(method="cv",number=3,verboseIter=T))
    #fitNNet1  <- avNNet(f, data=trainSet, repeats=25, size=20, decay=0.1, linout=T)
    modelFit <- ranger(f, data=trainSet, importance="impurity") #case.weights

    # evaluate overal performance
#    print( paste("RMSE for myModel:",   RMSE(1/testSet[,POI], 1/predict(modelFit,testSet[,-POI])$predictions) ) )
#    print( paste("RMSE for reference:", RMSE(1/testSet[,POI], testSet[,"ptTrg"]) ) )
#    print( paste("R2 for myModel:",     R2(1/testSet[,POI], 1/predict(modelFit,testSet[,-POI])$predictions ) ) )
#    print( paste("R2 for reference:",   R2(1/testSet[,POI], testSet[,"ptTrg"]) ) ) 

    list(modelFit, testSet, POI)
}

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

