require(leaps)
require(ggplot2)
source("../emtfPtRegression/utils.R")

mode_inv <- 15

mode = c(0, 0, 12, 0, 10, 5, 14, 0, 9, 5, 13, 3, 11, 7, 15)
df <- read.csv(file="muonGunPt3_100_emtf.csv",header=T,sep=',')

modelSel <- function(mode_inv){

    if( mode[mode_inv] == 0 ){
        print("Problem")
        return(NULL)
    }

    d1 <- df[df[,"mode.0."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
    d2 <- df[df[,"mode.1."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]

    colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
    colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)

    d <- rbind(d1,d2)

    if( mode_inv == 15 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   sat(abs(dPhi12),7),
                                   sat(abs(dPhi23),7),
                                   sat(abs(dPhi34),7),
                                   factor(ifelse(dPhi12>=0,0,1),levels=c(0,1)),
                                   factor(ifelse(dPhi23*dPhi12>=0,0,1),levels=c(0,1)),
                                   factor(ifelse(dPhi34*dPhi12>=0,0,1),levels=c(0,1)),
                                   sat(abs(dTheta12),2),
                                   sat(abs(dTheta23),2),
                                   sat(abs(dTheta34),2),
                                   as.factor(ifelse(dTheta23*dTheta34>=0,0,1)),
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
        predictors <- c("dPhi12", "dPhi23", "dPhi34", "sPhi12", "sPhi23", "sPhi34", "dTheta12", "dTheta23", "dTheta34", "sTheta234", "clct1", "clct2", "clct3", "clct4", "fr1", "fr2", "fr3", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )

        nvmax <- 39

    } else if( mode_inv == 14 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   sat(abs(dPhi23),10),
                                   sat(abs(dPhi34),10),
                                   factor(ifelse(dPhi23>=0,0,1),levels=c(0,1)),
                                   factor(ifelse(dPhi23*dPhi34>=0,0,1),levels=c(0,1)),
                                   sat(abs(dTheta23),7),
                                   sat(abs(dTheta34),7),
                                   factor(ifelse(dTheta23*dTheta34>=0,0,1),levels=c(0,1)),
                                   factor(clct2,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct3,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct4,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(fr2,levels=c(0,1)),
                                   factor(fr3,levels=c(0,1)),
                                   factor(fr4,levels=c(0,1))
                                 )
                         )
        predictors <- c("dPhi23", "dPhi34", "sPhi23", "sPhi234", "dTheta23", "dTheta34", "sTheta234", "clct2", "clct3", "clct4", "fr2", "fr3", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )

        nvmax <- 30

    } else if( mode_inv == 13 ){
        vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   sat(abs(dPhi13),9),
                                   sat(abs(dPhi34),9),
                                   factor(ifelse(dPhi13>=0,0,1),levels=c(0,1)),
                                   factor(ifelse(dPhi13*dPhi34>=0,0,1),levels=c(0,1)),
                                   sat(abs(dTheta13),7),
                                   sat(abs(dTheta34),7),
                                   factor(ifelse(dTheta13*dTheta34>=0,0,1),levels=c(0,1)),
                                   factor(clct1,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct3,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(clct4,levels=c(2,3,4,5,6,7,8,9,10)),
                                   factor(fr1,levels=c(0,1)),
                                   factor(fr3,levels=c(0,1)),
                                   factor(fr4,levels=c(0,1))
                                 )
                         )
        predictors <- c("dPhi13", "dPhi34", "sPhi13", "sPhi134", "dTheta13", "dTheta34", "sTheta134", "clct1", "clct3", "clct4", "fr1", "fr3", "fr4")
        colnames(vars) <- c("muPtGenInv", "muEtaGen", "ptTrg", predictors )

        nvmax <- 30

    }

    par(mfrow=c(2,2))

    set.seed(1)
    f <- as.formula(paste("muPtGenInv ~ ", paste(predictors, collapse= "+")))
    regfit.full <- regsubsets(f,data=vars,nvmax=nvmax) #method="forward") #- for nested sets
    regfit.summary <- summary(regfit.full)
    print(paste(" min=", which.min(regfit.summary$cp)))
    plot(regfit.summary$cp,xlab="num of vars",ylab="Cp")
    plot(regfit.full,scale="Cp")
    coef(regfit.full,10)

    part <- sample(seq(nrow(vars)), as.integer(nrow(vars)*0.75), replace=F)
    regfit.fwd <- regsubsets(f,data=vars[part,],nvmax=39,method="forward") # for nested sets
    val.errors <- rep(NA,nvmax)
    x.test <- model.matrix(f,data=vars[-part,])
    for(i in 1:nvmax){
        coefi <- coef(regfit.fwd ,id=i)
        pred  <- x.test[,names(coefi)]%*%coefi
        val.errors[i] <- mean((vars[-part,"muPtGenInv"]-pred)^2) # same as caret::RMSE(vars[-part,"muPtGenInv"],pred)^2
    }
    plot(sqrt(val.errors))
    #points(sqrt(regfit.fwd$rss[-1]/nrow(d)/0.79),pch=20,col="red")

    folds <- sample(rep(1:10,length=nrow(vars)))
    table(folds)
    cv.errors <- matrix(NA,10,nvmax)
    for(k in 1:10){
        best.fit <- regsubsets(f,data=vars[folds!=k,],nvmax=nvmax,method="forward")
        mod <- model.matrix(f,data=vars[folds==k,])
        for(i in 1:nvmax){
            coefi <- coef(best.fit ,id=i)
            pred  <- mod[,names(coefi)]%*%coefi
            cv.errors[k,i] <- mean((vars[folds==k,"muPtGenInv"]-pred)^2)
        }
    }
    mse.cv <- sqrt(apply(cv.errors,2,mean))
    plot(sqrt(mse.cv),pch=19,type="b")
    # so you didn't exhaust the predictors



    list(regfit.full,regfit.fwd,sqrt(val.errors),sqrt(mse.cv))
}
