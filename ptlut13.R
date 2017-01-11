#source("../emtfPtRegression/utils.R")

sat <- function(x, n){ m <- bitwShiftL(1L,n)-1 ; y <- x ; y[ y>m ] = m ; y[ y < -m ] = -m ; y }

predictors2address13 <- function(df){
  # df: dPhi13, dPhi34, dTheta13, dTheta34, clct1, clct3, clct4, fr1, fr3, fr4
  # set highest 4 bits [29:26] to indicate this was mode_inv=14 -> 0110
  address <- rep(0x1B000000,nrow(df))
  # again, ignore all of the signs
  address <- bitwOr(address, bitwShiftL(bitwAnd(sat(abs(df$dPhi13),9),0x1FF),0) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(sat(abs(df$dPhi34),9),0x1FF),0+9) )
  address <- bitwOr(address, bitwShiftL(c(0,0,0,1,2,3,4,0,5,6,7,0,0,0,0,0)[bitwAnd(as.integer(as.character(df$clct1)),0xF)+1],0+9+9) )
  address <- bitwOr(address, bitwShiftL(c(0,0,0,0,1,2,3,4,5,6,7,0,0,0,0,0)[bitwAnd(as.integer(as.character(df$clct3)),0xF)+1],0+9+9+3) )
  address <- bitwOr(address, bitwShiftL(c(0,0,0,0,0,0,0,0,1,2,3,0,0,0,0,0)[bitwAnd(as.integer(as.character(df$clct4)),0xF)+1],0+9+9+3+3) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(as.integer(as.character(df$fr1)),0x1),0+9+9+3+3+2) )
  address
}

address2predictors13 <- function(address){
  df <- data.frame(mode_inv = ifelse(bitwAnd(address,0x1C000000)==0x1C000000,14,0)) 
  df$dPhi13 <- bitwAnd(bitwShiftR(address,0),0x1FF)
  df$dPhi34 <- bitwAnd(bitwShiftR(address,0+9),0x1FF)
  df$dTheta13 <- 0
  df$dTheta34 <- 0
  df$clct1 <- factor( c(7,3,4,5,6,8,9,10)[bitwAnd(bitwShiftR(address,0+9+9),0x3)+1], levels=c(7,3,4,5,6,8,9,10))
  df$clct3 <- factor( c(3,4,5,6,7,8,9,10)[bitwAnd(bitwShiftR(address,0+9+9+3),0x3)+1], levels=c(3,4,5,6,7,8,9,10))
  df$clct4 <- factor( c(6,8,9,10)[bitwAnd(bitwShiftR(address,0+9+9+3+3),0x3)+1], levels=c(9,6,8,10))
  df$fr1 <- factor( c(0,1)[bitwAnd(bitwShiftR(address,0+9+9+3+3+2),0x1)+1], levels=c(0,1))
  df$fr3 <- 0
  df$fr4 <- 0  
  df
}

generatePtLUT13 <- function(){
  space <- data.frame(address=0:(bitwShiftL(1L,19)-1))
  df <- as.data.frame( apply(space,2,function(x){address2predictors13(x)}) )
  colnames(df) <- sub("address\\.","",colnames(df))
  # iterate manually over the rest of the predictors:
  address_high = 0
  max_addr_high = bitwShiftL(1L,2+2+2+1)

  while( address_high < max_addr_high ){
    df$clct1 <- factor( c(7,3,4,5,6,8,9,10)[bitwAnd(bitwShiftR(address,0+9+9),0x3)+1], levels=c(7,3,4,5,6,8,9,10))
    df$clct3 <- factor( c(3,4,5,6,7,8,9,10)[bitwAnd(bitwShiftR(address,0+9+9+3),0x3)+1], levels=c(3,4,5,6,7,8,9,10))
    df$clct4 <- factor( c(6,8,9,10)[bitwAnd(bitwShiftR(address_high,0+2+2),0x3)+1], levels=c(9,6,8,10))
    df$fr1   <- factor( c(0,1)[bitwAnd(bitwShiftR(address_high,0+2+2+2),0x1)+1], levels=c(0,1))

    print(paste(" clct1=",df[1,"clct1"]," clct3=",df[1,"clct3"]," clct4=",df[1,"clct4"]," fr1=",df[1,"fr1"]))
    write.table(file=paste("lut13_",address_high,".txt",sep=""), x = cbind(space, round(1/predict(modelFit13,df)$predictions,2)), row.names=F, col.names=F )
    print(paste("Finished ",address_high) )

    address_high <- address_high + 1
  }
}

