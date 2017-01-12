mode_inv <- 15
mode = c(0, 0, 12, 0, 10, 5, 14, 0, 9, 5, 13, 3, 11, 7, 15)
df <- read.csv(file="muonGunPt3_100_emtf.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
d2 <- df[df[,"mode.1."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]
colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)
d <- rbind(d1,d2)
source("../emtfPtRegression/utils.R")
require(leaps)
vars <- with(d,data.frame( 1/muPtGen,
                                   muEtaGen,
                                   pt,
                                   sat(abs(dPhi12),7),
                                   sat(abs(dPhi23),7),
                                   sat(abs(dPhi34),7),
                                   as.factor(ifelse(dPhi12>=0,0,1)),
                                   as.factor(ifelse(dPhi23*dPhi12>=0,0,1)),
                                   as.factor(ifelse(dPhi34*dPhi12>=0,0,1)),
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
f <- as.formula(paste("muPtGenInv ~ ", paste(predictors, collapse= "+")))
regfit.full <- regsubsets(f,data=vars,nvmax=39) #method="forward") #- for nested sets
regfit.summary <- summary(regfit.full)
which.min(regfit.summary$cp)
plot(regfit.summary$cp,xlab="num of vars",ylab="Cp")
plot(regfit.full,scale="Cp")
coef(regfit.full,10)

part <- sample(seq(nrow(d)), as.integer(nrow(d)*0.75), replace=F)
regfit.fwd <- regsubsets(f,data=vars[part,],nvmax=39,method="forward") # for nested sets
val.errors2 <- rep(NA,39)
x.test <- model.matrix(f,data=vars[-part,])
for(i in 1:39){
  coefi <- coef(regfit.fwd ,id=i)
  pred  <- x.test[,names(coefi)]%*%coefi
  val.errors[i] <- RMSE(vars[-part,"muPtGenInv"],pred)^2 #mean((vars[-part,"muPtGenInv"]-pred)^2)
}

plot(sqrt(val.errors))
points(sqrt(regfit.fwd$rss[-1]/nrow(d)/0.79),pch=20,col="red")

########################

folds <- sample(rep(1:10,length=nrow(d)))
table(folds)
cv.errors <- matrix(NA,10,39)
for(k in 1:10){
  best.fit <- regsubsets(f,data=vars[folds!=k,],nvmax=39,method="forward")
  mod <- model.matrix(f,data=vars[folds==k,])
  for(i in 1:39){
    coefi <- coef(best.fit ,id=i)
    pred  <- mod[,names(coefi)]%*%coefi
    cv.errors[k,i] <- mean((vars[folds==k,"muPtGenInv"]-pred)^2)
  }
}
rmse.cv <- sqrt(apply(cv.errors,2,mean))
plot(rmse.cv,pch=19,type="b")
# so you didn't exhaust the predictors

########################

dphi12 <- as.formula( 1/muPtGen ~ abs(dPhi12) )
anova( lm(dphi12, data = d) ) # this is significant F-statistics
dphi123 <- update( dphi12, ~ . + abs(dPhi23) )
dphi1234 <- update( dphi123, ~ . + abs(dPhi34) )
anova( lm( dphi12, data=d ), lm( dphi123, data=d ), lm( dphi1234, data=d ) ) # no use in dPhi23 on top of dPhi12
dphi124 <- update( dphi12, ~ . + abs(dPhi34) )
dphi124clct1 <- update( dphi124, ~ . + clct1 )
dphi124clct12 <- update( dphi124clct1, ~ . + clct2 )
dphi124clct123 <- update( dphi124clct12, ~ . + clct3 )
dphi124clct1234 <- update( dphi124clct123, ~ . + clct4 )

dphi124clct1234fr1 <- update( dphi124clct1234, ~ . + fr1 )
dphi124clct1234fr12 <- update( dphi124clct1234fr1, ~ . + fr2 )
dphi124clct1234fr123 <- update( dphi124clct1234fr12, ~ . + fr3 )
dphi124clct1234fr1234 <- update( dphi124clct1234fr123, ~ . + fr4 )

dphi124clct1234fr1234th12 <- update( dphi124clct1234fr1234, ~ . + dTheta12 )
dphi124clct1234fr1234th123 <- update( dphi124clct1234fr1234th12, ~ . + dTheta23 )
dphi124clct1234fr1234th1234 <- update( dphi124clct1234fr1234th123, ~ . + dTheta34 )

dphi124clct1234fr14th234 <- update( dphi124clct1234fr1, ~ . + fr4 + dTheta23 + dTheta34 )

anova( lm( dphi12, data=d ),
       lm( dphi124, data=d ),
       lm( dphi124clct1, data=d ),
       lm( dphi124clct12, data=d ),
       lm( dphi124clct123, data=d ),
       lm( dphi124clct1234, data=d ),
       lm( dphi124clct1234fr1, data=d ),
#       lm( dphi124clct1234fr14th234, data=d ),
       lm( dphi124clct1234fr12, data=d ),
       lm( dphi124clct1234fr123, data=d ),
       lm( dphi124clct1234fr1234, data=d ),
       lm( dphi124clct1234fr1234th12, data=d ),
       lm( dphi124clct1234fr1234th123, data=d ),
       lm( dphi124clct1234fr1234th1234, data=d )
     )

# indeed, dPhi23 - is not really needed:
x <- model.matrix(1/muPtGen ~ abs(dPhi12) + abs(dPhi23) + abs(dPhi34) + abs(dTheta12) + abs(dTheta23) + abs(dTheta34) - 1, data = d)
y <- 1/d$muPtGen
fit.lasso <- glmnet(x,y)
plot(fit.lasso,xvar="dev",label=T)
rownames(fit.lasso$beta)[8]

# stick to 2 bits for clct1
x <- model.matrix(1/muPtGen ~ abs(dPhi12) + abs(dPhi34) + abs(dTheta23) + abs(dTheta34) + as.factor(sign(dPhi12)) + as.factor(sign(dPhi34)) + as.factor(sign(dTheta23)) + as.factor(sign(dTheta34)) +  as.factor(c(0,0,1,0,0,2,0,3,0,0)[clct1]) - 1, data = d)
y <- 1/d$muPtGen
fit.lasso <- glmnet(x,y)
plot(fit.lasso,xvar="dev",label=T)

