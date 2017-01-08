source("utils.R")

predictors2address14 <- function(df){
  # df: dPhi12, dPhi23, dPhi34, dTheta12, dTheta23, dTheta34, clct1, clct2, clct3, clct4, fr1, fr2, fr3, fr4
  # address: dPhi23[9:0] | dPhi34[9:0] | sat(dTheta23,2) | recode(clct3)[1:0]) | recode(clct4)[1:0]) 
  # set highest 4 bits [29:26] to indicate this was mode_inv=14 -> 0111
  address <- rep(0x1C000000,nrow(df))
  # again, ignore all of the signs
  address <- bitwOr(address, bitwShiftL(bitwAnd(abs(df$dPhi23),0x3FF),0) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(abs(df$dPhi34),0x3FF),0+10) )
  address <- bitwOr(address, bitwShiftL(sat(abs(df$dTheta23),2),0+10+10) )
  address <- bitwOr(address, bitwShiftL(c(0,0,0,0,3,1,0,2,0,0,0,0,0,0,0,0)[bitwAnd(df$clct3,0xF)],0+10+10+2) )
  address <- bitwOr(address, bitwShiftL(c(0,0,0,0,3,1,0,2,0,0,0,0,0,0,0,0)[bitwAnd(df$clct4,0xF)],0+10+10+2+2) )
  address
}

address2predictors14 <- function(address){
  df <- data.frame(mode_inv = ifelse(bitwAnd(address,0x1C000000)==0x1C000000,14,0)) 
  df$dPhi12 <- 0
  df$dPhi23 <- bitwAnd(bitwShiftR(address,0),0x3FF)
  df$dPhi34 <- bitwAnd(bitwShiftR(address,10),0x3FF)
  df$dTheta12 <- 0
  df$dTheta23 <- bitwAnd(bitwShiftR(address,10+10),0x3)
  df$dTheta34 <- 0
  df$clct1 <- 0
  df$clct2 <- 0
  df$clct3 <- c(10,6,9,5)[bitwAnd(bitwShiftR(address,10+10+2),0x3)+1]
  df$clct4 <- c(10,6,9,5)[bitwAnd(bitwShiftR(address,10+10+2+2),0x3)+1]
  df$fr1 <- 0
  df$fr2 <- 0
  df$fr3 <- 0
  df$fr4 <- 0  
  df
}

generatePtLUT14 <- function(){
  space <- data.frame(address=0:(bitwShiftL(1L,20)-1))
  df <- as.data.frame( apply(space,2,function(x){address2predictors14(x)}) )
  colnames(df) <- sub("address\\.","",colnames(df))
  # iterate manually over the rest of the predictors:
  address_high = 0
  max_addr_high = bitwShiftL(1L,2+2+2)

  while( address_high < max_addr_high ){
    df$dTheta23 <- bitwAnd(bitwShiftR(address_high,0),0x3)
    df$dTheta34 <- bitwAnd(bitwShiftR(address_high,0+2),0x3)
    df$clct3    <- bitwAnd(bitwShiftR(address_high,0+2+2),0x3)
    df$clct4    <- bitwAnd(bitwShiftR(address_high,0+2+2+2),0x3)

    print(paste("dTheta23=",df[1,"dTheta23"]," clct3=",df[1,"clct3"]," clct4=",df[1,"clct4"]))
    write.table(file=paste("lut14_",address_high,".txt",sep=""), x = cbind(space, round(1/predict(modelFit14,df)$predictions,2)) )
    print(paste("Finished ",address_high) )

    address_high <- address_high + 1
  }
}

