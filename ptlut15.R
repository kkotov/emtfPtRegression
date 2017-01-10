#source("utils.R")

sat <- function(x, n){ m <- bitwShiftL(1L,n)-1 ; y <- x ; y[ y>m ] = m ; y[ y < -m ] = -m ; y }

predictors2address15 <- function(df){
  # df: dPhi12, dPhi23, dPhi34, dTheta12, dTheta23, dTheta34, clct1, clct2, clct3, clct4, fr1, fr2, fr3, fr4
  # set highest bit [29:29] to indicate this was mode_inv=15
  address <- rep(0x20000000,nrow(df))
  # ignore all of the signs
  address <- bitwOr(address, bitwShiftL(bitwAnd(sat(abs(df$dPhi12),7),0x7F),0) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(sat(abs(df$dPhi23),7),0x7F),0+7) )
  address <- bitwOr(address, bitwShiftL(bitwAnd(sat(abs(df$dPhi34),7),0x7F),0+7+7) )
  address <- bitwOr(address, bitwShiftL(ifelse(df$dPhi23*df$dPhi12>=0,0,1),0+7+7+7) )
  address <- bitwOr(address, bitwShiftL(ifelse(df$dPhi34*df$dPhi12>=0,0,1),0+7+7+7+1) )
  address <- bitwOr(address, bitwShiftL(sat(abs(df$dTheta23),2),0+7+7+7+1+1) )
  address <- bitwOr(address, bitwShiftL(c(0,0,0,0,0,0,1,0,2,0,3,0,0,0,0,0)[bitwAnd(as.integer(as.character(df$clct1)),0xF)+1],0+7+7+7+1+1+2) ) # factor with integer levels is ok here
  address
}

address2predictors15 <- function(address){
  #if(bitwAnd(address,0x20000000) != 0x20000000)
  df <- data.frame(mode_inv = rep(15,length(address)))
  df$dPhi12 <- bitwAnd(bitwShiftR(address,0),0x7F)
  df$dPhi23 <- bitwAnd(bitwShiftR(address,0+7),0x7F)
  df$dPhi34 <- bitwAnd(bitwShiftR(address,0+7+7),0x7F)
  df$dPhi23 <- df$dPhi23 * ifelse( bitwAnd(bitwShiftR(address,0+7+7+7),  0x1)==1, -1 , 1)
  df$dPhi34 <- df$dPhi34 * ifelse( bitwAnd(bitwShiftR(address,0+7+7+7+1),0x1)==1, -1 , 1)
  df$dTheta12 <- 0
  df$dTheta23 <- bitwAnd(bitwShiftR(address,0+7+7+7+1+1),0x3)
  df$dTheta34 <- 0
  df$clct1 <- factor( c(9,6,8,10)[bitwAnd(bitwShiftR(address,0+7+7+7+1+1+2),0x3)+1], levels=c(9,6,8,10))
  df$clct2 <- 0
  df$clct3 <- 0
  df$clct4 <- 0
  df$fr1 <- 0
  df$fr2 <- 0
  df$fr3 <- 0
  df$fr4 <- 0
  df
}

generatePtLUT15 <- function(){
  space <- data.frame(address=0:(bitwShiftL(1L,21)-1))
  df <- as.data.frame( apply(space,2,function(x){address2predictors15(x)}) )
  colnames(df) <- sub("address\\.","",colnames(df))
  # iterate manually over the rest of the predictors:
  address_high = 0
  max_addr_high = bitwShiftL(1L,1+1+2+2) #+1

  while( address_high < max_addr_high ){
    orig23 <- df$dPhi23
    orig34 <- df$dPhi34
    df$dPhi23    <- df$dPhi23 * ifelse( bitwAnd(bitwShiftR(address_high,0),  0x1)==1, -1, 1)
    df$dPhi34    <- df$dPhi34 * ifelse( bitwAnd(bitwShiftR(address_high,0+1),0x1)==1, -1, 1)
    df$dTheta23  <- bitwAnd(bitwShiftR(address_high,0+1+1),0x3)
    df$clct1     <- factor( c(9,6,8,10)[bitwAnd(bitwShiftR(address_high,0+1+1+2),0x3)+1], levels=c(9,6,8,10) )#+1

#    if( predictors2address15() )

    print(paste("sPhi23=",df[1,"sPhi23"],"sPhi34=",df[1,"sPhi34"],"dTheta23=",df[1,"dTheta23"]," clct1=",df[1,"clct1"]))
    write.table(file=paste("lut15_",address_high,".txt",sep=""), x = cbind(space, round(1/predict(modelFit15,df)$predictions,2)), row.names=F, col.names=F )
    print(paste("Finished ",address_high) )

    df$dPhi23 <- orig23
    df$dPhi34 <- orig34

    address_high <- address_high + 1
  }
}

