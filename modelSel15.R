mode_inv <- 15
mode = c(0, 0, 12, 0, 10, 5, 14, 0, 9, 5, 13, 3, 11, 7, 15)
df <- read.csv(file="muonGunPt3_100_emtf.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
d2 <- df[df[,"mode.1."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]
colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)
d <- rbind(d1,d2)

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

