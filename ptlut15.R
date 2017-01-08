#source("utils.R")

sat <- function(x, n){ m <- bitwShiftL(1L,n)-1 ; y <- x ; y[ y>m ] = m ; y }

predictors2address15 <- function(df){
  # df: dPhi12, dPhi23, dPhi34, dTheta12, dTheta23, dTheta34, clct1, clct2, clct3, clct4, fr1, fr2, fr3, fr4
  # address: dPhi12[9:0] | dPhi34[9:0] | sat(dTheta23,2) | sat(dTheta34,2) | recode(clct1)[1:0]) | recode(clct2)[1:0]) | fr1[0]
  # set highest bit [29:29] to indicate this was mode_inv=15
  address <- rep(0x20000000,nrow(df))
  # ignore all of the signs
  address <- bitwOr(address, bitwShiftL(bitwAnd(abs(df$dPhi12),0x3FF),0) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(abs(df$dPhi34),0x3FF),0+10) )
  address <- bitwOr(address, bitwShiftL(sat(abs(df$dTheta23),2),0+10+10) )
  address <- bitwOr(address, bitwShiftL(sat(abs(df$dTheta34),2),0+10+10+2) )
  address <- bitwOr(address, bitwShiftL(c(0,0,3,0,0,2,0,1,0,0,0,0,0,0,0,0)[bitwAnd(df$clct1,0xF)+1],0+10+10+2+2) )
  address <- bitwOr(address, bitwShiftL(c(0,0,3,0,0,2,0,1,0,0,0,0,0,0,0,0)[bitwAnd(df$clct2,0xF)+1],0+10+10+2+2+2) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(df$fr1,0x1),0+10+10+2+2+2+2) )
  address
}

address2predictors15 <- function(address){
  #if(bitwAnd(address,0x20000000) != 0x20000000)
  df <- data.frame(mode_inv = rep(15,length(address)))
  df$dPhi12 <- bitwAnd(bitwShiftR(address,0),0x3FF)
  df$dPhi23 <- 0
  df$dPhi34 <- bitwAnd(bitwShiftR(address,10),0x3FF)
  df$dTheta12 <- 0
  df$dTheta23 <- bitwAnd(bitwShiftR(address,10+10),0x3)
  df$dTheta34 <- bitwAnd(bitwShiftR(address,10+10+2),0x3)
  df$clct1 <- c(10,8,6,3)[bitwAnd(bitwShiftR(address,10+10+2+2),0x3)+1]
  df$clct2 <- c(10,8,6,3)[bitwAnd(bitwShiftR(address,10+10+2+2+2),0x3)+1]
  df$clct3 <- 0
  df$clct4 <- 0
  df$fr1 <- bitwAnd(bitwShiftR(address,10+10+2+2+2+2),0x1)
  df$fr2 <- 0
  df$fr3 <- 0
  df$fr4 <- 0  
  df
}

generatePtLUT15 <- function(){
  space <- data.frame(address=0:(bitwShiftL(1L,20)-1))
  df <- as.data.frame( apply(space,2,function(x){address2predictors15(x)}) )
  colnames(df) <- sub("address\\.","",colnames(df))
  # iterate manually over the rest of the predictors:
  address_high = 134
  max_addr_high = bitwShiftL(1L,2+2+2+2+1)

  while( address_high < max_addr_high ){
    df$dTheta23 <- bitwAnd(bitwShiftR(address_high,0),0x3)
    df$dTheta34 <- bitwAnd(bitwShiftR(address_high,0+2),0x3)
    df$clct1    <- bitwAnd(bitwShiftR(address_high,0+2+2),0x3)
    df$clct2    <- bitwAnd(bitwShiftR(address_high,0+2+2+2),0x3)
    df$fr1      <- bitwAnd(bitwShiftR(address_high,0+2+2+2+2),0x1)

    print(paste("dTheta23=",df[1,"dTheta23"]," dTheta34=",df[1,"dTheta34"]," clct1=",df[1,"clct1"]," clct2=",df[1,"clct2"]," fr1=",df[1,"fr1"]))
    write.table(file=paste("lut15_",address_high,".txt",sep=""), x = cbind(space, round(1/predict(modelFit15,df)$predictions,2)) )
    print(paste("Finished ",address_high) )

    address_high <- address_high + 1
  }
}

