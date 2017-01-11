#include<tuple>

unsigned int sat(unsigned int x, unsigned int n){ unsigned int m = (1<<n)-1; if(x<m) return x; return m; }

unsigned int predictors2address15(int dPhi12, int dPhi23, int dPhi34, int dTheta12, int dTheta23, int dTheta34, int clct1, int clct2, int clct3, int clct4, int fr1, int fr2, int fr3, int fr4){
  unsigned int address = 0;
  // set highest bit [29:29] to indicate this was mode_inv=15
  // address |= 0x20000000;
  // ignore all of the signs
  address |= (sat(abs(dPhi12),7)&0x7F) << 0;
  address |= (sat(abs(dPhi23),7)&0x7F) << (0+7);
  address |= (sat(abs(dPhi34),7)&0x7F) << (7+7);
  address |= (dPhi23*dPhi12>=0?0:1) << (7+7+7);
  address |= (dPhi34*dPhi12>=0?0:1) << (7+7+7+1);
  address |= (sat(abs(dTheta23),2)&0x3) << (7+7+7+1+1);
  address |= ((const int[]){0,0,0,0,0,0,1,0,2,0,3,0,0,0,0,0,0})[(clct1&0xF)] << (7+7+7+1+1+2);
  return address;
}

std::tuple<int,int,int,int,int,int,int,int,int,int,int,int,int,int> predictors2address15(unsigned int address){
  int dPhi12=0, dPhi23=0, dPhi34=0, dTheta12=0, dTheta23=0, dTheta34=0, clct1=0, clct2=0, clct3=0, clct4=0, fr1=0, fr2=0, fr3=0, fr4=0;

  dPhi12 = (address>>0)&0x7F;
  dPhi23 = (address>>(0+7))&0x7F; 
  dPhi34 = (address>>(0+7+7))&0x7F; 

  unsigned int sPhi23 = (address>>(0+7+7+7))&0x1;
  unsigned int sPhi34 = (address>>(0+7+7+7+1))&0x1;
  dPhi23 *= (sPhi23 ? -1 : 1);
  dPhi34 *= (sPhi34 ? -1 : 1);

  dTheta23 = (address>>(0+7+7+7+1+1))&0x3;

  clct1 = ((const int[]){9,6,8,10})[(address>>(0+7+7+7+1+1+2))&0x3];

  return std::make_tuple(dPhi12,dPhi23,dPhi34,dTheta12,dTheta23,dTheta34,clct1,clct2,clct3,clct4,fr1,fr2,fr3,fr4);
}

unsigned int predictors2address14(int dPhi23, int dPhi34, int dTheta23, int dTheta34, int clct2, int clct3, int clct4, int fr2=0, int fr3=0, int fr4=0){
  unsigned int address = 0;
  // set highest bit [29:26] to indicate this was mode_inv=14
  // address |= 0x1C000000;
  // ignore all of the signs
  address |= (sat(abs(dPhi23),10)&0x3FF) << (0);
  address |= (sat(abs(dPhi34),10)&0x3FF) << (0+10);
  address |= ((const int[]){0,0,0,0,0,0,0,0,1,2,3,0,0,0,0,0,0})[(clct2&0xF)] << (10+10);
  address |= ((const int[]){0,0,0,0,0,0,0,0,1,2,3,0,0,0,0,0,0})[(clct3&0xF)] << (10+10+2);
  address |= ((const int[]){0,0,0,0,0,0,0,0,1,2,3,0,0,0,0,0,0})[(clct4&0xF)] << (10+10+2+2);
  return address;
}

