unsigned int sat(unsigned int x, unsigned int n){ unsigned int m = (1<<n)-1; if(x<m) return x; return m; }

unsigned int predictors2address15(int dPhi12, int dPhi23, int dPhi34, int dTheta12, int dTheta23, int dTheta34, int clct1, int clct2, int clct3, int clct4, int fr1, int fr2, int fr3, int fr4){
  // address: dPhi12[9:0] | dPhi34[9:0] | sat(dTheta23,2) | sat(dTheta34,2) | recode(clct1)[1:0]) | recode(clct2)[1:0]) | fr1[0]
  unsigned int address = 0;
  // set highest bit [29:29] to indicate this was mode_inv=15
  // address |= 0x20000000;
  // ignore all of the signs
  address |= (dPhi12&0x3FF) << 0;
  address |= (dPhi34&0x3FF) << 10;
  address |= sat(dTheta23,2) << 10+10;
  address |= sat(dTheta34,2) << 10+10+2;
  address |= ({0,0,3,0,0,2,0,1,0,0,0,0,0,0,0,0}[(clct1&0xF)]) << (10+10+2+2);
  address |= bitwOr(address, bitwShiftL(c{0,0,3,0,0,2,0,1,0,0,0,0,0,0,0,0}[ ((clct2&0xF) << 10+10+2+2+2);
  address <- bitwOr(address, bitwShiftL(bitwAnd(df$fr1,0x1),0+10+10+2+2+2+2) )
  address
}

address2predictors15 <- function(address){
  df <- data.frame(mode_inv = ifelse(bitwAnd(address,0x20000000),15,0)) 
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


