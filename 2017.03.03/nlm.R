# http://www.stat.umn.edu/geyer/5931/mle/mle.pdf
# http://www.ms.uky.edu/~mai/sta321/MLEexample.pdf

mode_inv <- 15
mode = c(0, 0, 12, 0, 10, 5, 14, 0, 9, 5, 13, 3, 11, 7, 15)
df <- read.csv(file="../../pt/SingleMu_Pt1To1000_FlatRandomOneOverPt.csv",header=T,sep=',')
d1 <- df[df[,"mode.0."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".0.",colnames(df),fixed=T) ) ]
d2 <- df[df[,"mode.1."]==mode[mode_inv], c( grep("\\.[0-1]\\.",colnames(df),invert=T) , grep(".1.",colnames(df),fixed=T) ) ]
colnames(d1) <- sub(".0.", "", colnames(d1),fixed=T)
colnames(d2) <- sub(".1.", "", colnames(d2),fixed=T)
d <- rbind(d1,d2)

source("../metrics.R")
binning <- seq(0,100,2)
slimDF <- with(d, data.frame(true_pT = muPtGen, response_pT = pt) )
slimDF$trueBin <- sapply(slimDF$true_pT, findBin, binning)
pSpec <- aggregate(slimDF, by=list(bin=slimDF$trueBin), function(x) x )
norms <- sapply(pSpec$response_pT,length)
counts  <- t(sapply(pSpec$response_pT,function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
turnOn <- counts/norms

files <- paste("../2017.02.10/r",seq(6,27,1),".RData",sep='')
for(f in files[c(1,2,3,7,8,9,10,12,13,14,15,16,17,18,19,20,21,22)]) load(f)
rate <- r6 + r7 + r8 + r12 + r13 + r14 + r15 + r17 + r18 + r19 + r20 + r21 + r22 + r23 + r24 + r25 + r26 + r27

nBins <- length(binning)
dfXY <- data.frame( x=runif(1e8,1,1000), y=runif(1e8) )
pt <- dfXY[ 1/dfXY$x^2 > dfXY$y,"x"]
rm(dfXY)
qqplot(runif(30000,0.001,1)^-1,pt) # for the power spectrum this is much more efficient generator
# check this out:
# pt <- dfXY[ 1/dfXY$x^4 > dfXY$y,"x"]
# qqplot(runif(30000,0.00001,1)^(-1/3),pt)

rate2 <- sapply(binning, function(x) sum(pt > x) )

f <- function(trueRatePar, measuredRate) {
    norm     <- trueRatePar[1]
    powerLaw <- trueRatePar[2]
    shift    <- trueRatePar[3]
    trueRate <- sapply(binning,function(x) norm*measuredRate[1]*((binning[1]+shift)^powerLaw)/((x+shift)^powerLaw))
    res <- sum( (measuredRate - trueRate)^2 )
#    attr(res, "gradient") <- 2*c(sum((trueRate-measuredRate)*trueRate/norm), -sum((trueRate-measuredRate)*trueRate*log(binning+1)))
    res
}

nlm(f, c(1,2,1), measuredRate = rate2, hessian=T)
#solve(hessian) # to get covariance matrix

###########################################
binning <- seq(1,100,0.1)
nBins <- length(binning)
rate2 <- sapply(binning, function(x) sum(pt > x) )

idealTurnOn <- matrix(rep(0,nBins*nBins), ncol=nBins, nrow=nBins)
for(bin in 1:nBins) for(thr in 1:nBins) idealTurnOn[thr,bin] = (atan(0.1*(bin-thr+0.5)) + 3.1415927/2.)/3.1415927

f2 <- function(trueRatePar, binning, turnOn, measuredRate) {
    norm     <- trueRatePar[1]
    powerLaw <- trueRatePar[2]
    shift    <- trueRatePar[3]
    trueRate <- norm*(measuredRate[1]-measuredRate[length(binning)])/(binning+shift)^powerLaw / (1/(binning[1]+shift)^(powerLaw-1) - 1/(binning[length(binning)]+shift)^(powerLaw-1))
#    sum( (measuredRate - ((sum(trueRate)-cumsum(trueRate))*(binning[2]-binning[1])+measuredRate[length(binning)]))^2 )
    sum( (measuredRate - ((t(turnOn) %*% trueRate)*(binning[2]-binning[1])+measuredRate[length(binning)]))^2 )
}

nlm(f2, c(1,2,1) , binning = binning, turnOn = t(idealTurnOn), measuredRate = rate2, hessian=T)

binning <- seq(2,100,2)

nlm(f2, c(1,2,1) , binning = binning, turnOn = turnOn[2:51,2:51], measuredRate = rate[2:51], hessian=T)

##############################

binning <- seq(2,100,2)

pt <- runif(30000000,0.000001,1)^(-1/2)
rate3 <- sapply(binning, function(x) sum(pt > x) )

pt2 <- runif(30000000,0.00001,1)^(-1/3)
rate4 <- sapply(binning, function(x) sum(pt2 > x) )

plot(binning,rate[2:51])
lines(binning, (t(turnOn[2:51,2:51]) %*% rate4)*0.05,  col='red')
lines(binning, (t(turnOn[2:51,2:51]) %*% rate3)*0.015, col='blue')

nlm(f2, c(1,2,1) , binning = binning, turnOn = turnOn[2:51,2:51], measuredRate = drop(t(turnOn[2:51,2:51]) %*% rate4), hessian=T)

