mode_inv <- 14
mode = c(0, 0, 12, 0, 10, 5, 14, 0, 9, 5, 13, 3, 11, 7, 15)
df <- read.csv(file="muonGunPt3_100_emtf.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
d2 <- df[df[,"mode.1."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]
colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)
d <- rbind(d1,d2)

dphi23 <- as.formula( 1/muPtGen ~ abs(dPhi23) )
anova( lm(dphi23, data = d) ) # this is significant F-statistics
dphi234 <- update( dphi23, ~ . + abs(dPhi34) )
anova( lm( dphi23, data=d ), lm( dphi234, data=d ) ) # no use in dPhi23 on top of dPhi12
dphi234clct2 <- update( dphi234, ~ . + clct2 )
dphi234clct23 <- update( dphi234clct2, ~ . + clct3 )
dphi234clct234 <- update( dphi234clct23, ~ . + clct4 )

dphi234clct234fr2 <- update( dphi234clct234, ~ . + fr2 )
dphi234clct234fr23 <- update( dphi234clct234fr2, ~ . + fr3 )
dphi234clct234fr234 <- update( dphi234clct234fr23, ~ . + fr4 )

dphi234clct234fr234th23 <- update( dphi234clct234fr234, ~ . + dTheta23 )
dphi234clct234fr234th234 <- update( dphi234clct234fr234th23, ~ . + dTheta34 )

anova( lm( dphi23, data=d ),
       lm( dphi234, data=d ),
       lm( dphi234clct2, data=d ),
       lm( dphi234clct23, data=d ),
       lm( dphi234clct234, data=d ),
       lm( dphi234clct234fr2, data=d ),
       lm( dphi234clct234fr23, data=d ),
       lm( dphi234clct234fr234, data=d ),
       lm( dphi234clct234fr234th23, data=d ),
       lm( dphi234clct234fr234th234, data=d )
     )

dphi234th23 <- update( dphi234, ~ . + abs(dTheta23) )
dphi234th23clct3 <- update( dphi234th23, ~ . + clct3 )

dphi234clct3 <- update( dphi234, ~ . + abs(clct3) )
dphi234clct3th23 <- update( dphi234clct3, ~ . + abs(dTheta23) )

x <- model.matrix(1/muPtGen ~ abs(dPhi23) + abs(dPhi34) + as.factor(clct3) + as.factor(sign(dPhi23)) + as.factor(sign(dPhi34)) - 1, data = d)
y <- 1/d$muPtGen
fit.lasso <- glmnet(x,y)
plot(fit.lasso,xvar="dev",label=T)
rownames(fit.lasso$beta)[8]

R2(y, predict(fit.lasso,x,s=0.02) )

x <- model.matrix(1/muPtGen ~ abs(dPhi23) + abs(dPhi34) + clct3 + clct4 - 1, data = d)
fit.lasso <- glmnet(x,y)
R2(y, predict(fit.lasso,x,s=0.) )

x <- model.matrix(1/muPtGen ~ abs(dPhi23) + abs(dPhi34) + as.factor(c(0,0,0,0,3,1,0,2,0,0)[clct3]) + as.factor(c(0,0,0,0,3,1,0,2,0,0)[clct4]) - 1, data=d)
fit.lasso <- glmnet(x,y)
R2(y, predict(fit.lasso,x,s=0.) )
