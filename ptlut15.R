#source("utils.R")

predictors2address15 <- function(df){
  # df should contain full precision: theta, ring1, dPhi12, dPhi23, dPhi34, dTheta14, clct1, fr1
  # set highest bit [29:29] to indicate this was mode_inv=15
  address <- rep(0x00000000,nrow(df))
  # truncate precision
  address <- bitwOr(address, bitwShiftL(bitwAnd(msb(abs(sat(df$dPhi12,9)),9,2),0x7F),0) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(msb(abs(sat(df$dPhi23,7)),7,2),0x1F),0+7) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(msb(abs(sat(df$dPhi34,7)),7,2),0x1F),0+7+5) )
  address <- bitwOr(address, bitwShiftL(ifelse(df$dPhi23*df$dPhi12>=0,rep(0,dim(df)[2]),rep(1,dim(df)[2])),0+7+5+5) )
  address <- bitwOr(address, bitwShiftL(ifelse(df$dPhi34*df$dPhi12>=0,rep(0,dim(df)[2]),rep(1,dim(df)[2])),0+7+5+5+1) )
  address <- bitwOr(address, bitwShiftL(sat(abs(df$dTheta14),2),0+7+5+5+1+1) )
  address <- bitwOr(address, bitwShiftL(c(0,0,0,0,1,1,2,2,3,3,3,0,0,0,0,0)[bitwAnd(as.integer(as.character(df$clct1)),0xF)+1],0+7+5+5+1+1+2) ) # factor with integer levels is ok here
  address <- bitwOr(address, bitwShiftL(bitwAnd(as.integer(as.character(df$fr1)),0x1),0+7+5+5+1+1+2+2) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(msb(abs(df$theta) + c(0,6,6,0)[as.integer(as.character(df$ring1))],7,2),0x1F),0+7+5+5+1+1+2+2+1) )
  address
}

address2predictors15 <- function(address){
  #assert if(bitwAnd(address,0x20000000) != 0x20000000)
  df <- data.frame(mode_inv = rep(15,length(address)))
  df$dPhi12 <- bitwShiftL(bitwAnd(bitwShiftR(address,0),    0x7F),2)
  df$dPhi23 <- bitwShiftL(bitwAnd(bitwShiftR(address,0+7),  0x1F),2)
  df$dPhi34 <- bitwShiftL(bitwAnd(bitwShiftR(address,0+7+5),0x1F),2)
  df$dPhi23 <- df$dPhi23 * ifelse( bitwAnd(bitwShiftR(address,0+7+5+5),  0x1)==1, rep(-1,length(address)) , rep(1,length(address)))
  df$dPhi34 <- df$dPhi34 * ifelse( bitwAnd(bitwShiftR(address,0+7+5+5+1),0x1)==1, rep(-1,length(address)) , rep(1,length(address)))
  df$dPhi13 <- df$dPhi12 + df$dPhi23
  df$dPhi14 <- df$dPhi12 + df$dPhi23 + df$dPhi34
  df$dPhi24 <- df$dPhi23 + df$dPhi34
  df$dTheta12 <- 0
  df$dTheta23 <- 0
  df$dTheta34 <- 0
  df$dTheta13 <- 0
  df$dTheta14 <- bitwAnd(bitwShiftR(address,0+7+5+5+1+1),0x3)
  df$dTheta24 <- 0
  df$clct1 <- factor( c(3,5,7,10)[bitwAnd(bitwShiftR(address,0+7+5+5+1+1+2),0x3)+1], levels=c(3,5,7,10))
  df$clct2 <- 0
  df$clct3 <- 0
  df$clct4 <- 0
  df$fr1 <- bitwAnd(bitwShiftR(address,0+7+5+5+1+1+2+2),0x1)
  df$fr2 <- 0
  df$fr3 <- 0
  df$fr4 <- 0
  df$theta <- bitwAnd(bitwShiftR(address,0+7+5+5+1+1+2+2+1),0x1F)
  df$ring1 <- ifelse(df$theta>50, rep(2,length(address)),rep(1,length(address)))
  df$theta <- ifelse(df$ring1==2, df$theta-6, df$theta)
  df
}

compressPredictors <- function(df){
  comp <- data.frame( theta = msb(df$theta + c(0,6,6,0)[as.integer(as.character(df$ring1))],7,2) )
  comp$zero <- 0
  comp$one  <- 0
  comp$dPhi12 <- msb(abs(sat(df$dPhi12,9)),9,2)
  comp$dPhi23 <- msb(abs(sat(df$dPhi23,7)),7,2)
  comp$dPhi34 <- msb(abs(sat(df$dPhi34,7)),7,2)
  comp$sPhi123 <- as.factor(ifelse(df$dPhi23*df$dPhi12>=0,comp$zero,comp$one))
  comp$sPhi134 <- as.factor(ifelse(df$dPhi34*df$dPhi12>=0,comp$zero,comp$one))
  comp$dPhi13 <- msb(abs(sat(df$dPhi12,9)),9,2) + ifelse(df$dPhi23*df$dPhi12>=0,comp$one,-comp$one)*msb(abs(sat(df$dPhi23,7)),7,2)
  comp$dPhi14 <- msb(abs(sat(df$dPhi12,9)),9,2) + ifelse(df$dPhi23*df$dPhi12>=0,comp$one,-comp$one)*msb(abs(sat(df$dPhi23,7)),7,2) + ifelse(df$dPhi34*df$dPhi12>=0,comp$one,-comp$one)*msb(abs(sat(df$dPhi34,7)),7,2)
  comp$dPhi24 <- msb(abs(sat(df$dPhi23,7)),7,2) + ifelse(df$dPhi34*df$dPhi12>=0,comp$one,-comp$one)*msb(abs(sat(df$dPhi34,7)),7,2)
  comp$dTheta14 <- abs(sat(df$dTheta14,2))
  comp$clct1 <- c(0,0,0,0,1,1,2,2,3,3,3,0,0,0,0,0)[bitwAnd(as.integer(as.character(df$clct1)),0xF)+1]
  comp$fr1
  comp
}

generatePtLUT15 <- function(modelFit){
  space <- data.frame(address=0:(bitwShiftL(1L,20)-1))
  df <- as.data.frame( apply(space,2,function(x){address2predictors15(x)}) )
  colnames(df) <- sub("address\\.","",colnames(df))
  # iterate manually over the rest of the predictors:
  address_high = 0
  max_addr_high = bitwShiftL(1L,2+2+1+4)

  while( address_high < max_addr_high ){
    df$dTheta14  <- bitwAnd(bitwShiftR(address_high,0),0x3)
    df$clct1     <- factor( c(3,5,7,10)[bitwAnd(bitwShiftR(address_high,0+2),0x3)+1], levels=c(3,5,7,10) )
    df$fr1       <- bitwAnd(bitwShiftR(address_high,0+2+2),0x1)
    df$theta     <- bitwAnd(bitwShiftR(address_high,0+2+2+1),0xF)
    df$dPhi13    <- df$dPhi12 + ifelse(df$sPhi123, -1, 1) * df$dPhi23
    df$dPhi14    <- df$dPhi12 + ifelse(df$sPhi123, -1, 1) * df$dPhi23 + ifelse(df$sPhi134, -1, 1) * df$dPhi34
    df$dPhi24    <- df$dPhi23 + ifelse(df$sPhi134, -1, 1) * df$dPhi34

    print(paste("dTheta14=",df[1,"dTheta14"],"clct1=",df[1,"clct1"],"fr1=",df[1,"fr1"],"theta=",df[1,"theta"]))
    write.table(file=paste("lut15_",address_high,".txt",sep=""), x = cbind(space, round(1/predict(modelFit,df)$predictions,2)), row.names=F, col.names=F )
    print(paste("Finished ",address_high) )

    address_high <- address_high + 1
  }
}

