#include<tuple>

unsigned int sat(unsigned int x, unsigned int n){ unsigned int m = (1<<n)-1; if(x>m) return m; if(x<-m) return -m; return x; }
unsigned int lsb(unsigned int x, unsigned int n){ return (x&((1<<n)-1)); }
unsigned int msb(unsigned int x, unsigned int n, unsigned int m){ return (x>>m)&((1<<(n+1-m))-1); }

unsigned int predictors2address15(int dPhi12, int dPhi23, int dPhi34, int dTheta12, int dTheta23, int dTheta34, unsigned int theta, unsigned int ring1, int clct1, int clct2, int clct3, int clct4, int fr1, int fr2, int fr3, int fr4){
  unsigned int address = 0;
  // set highest bit [29:29] to indicate this was mode_inv=15
  // address |= 0x20000000;
  // ignore all of the signs
  address |= (msb(sat(abs(dPhi12),9),9,2) & 0x7F) << 0;
  address |= (msb(sat(abs(dPhi23),7),7,2) & 0x1F) << (0+7);
  address |= (msb(sat(abs(dPhi34),7),7,2) & 0x1F) << (7+5);
  address |= (dPhi23*dPhi12>=0?0:1) << (7+5+5);
  address |= (dPhi34*dPhi12>=0?0:1) << (7+5+5+1);
  address |= (sat(abs(dTheta14),2) & 0x3) << (7+5+5+1+1);
  address |= ((const int[]){0,0,0,0,1,1,2,2,3,3,3,0,0,0,0,0})[(clct1&0xF)] << (7+5+5+1+1+2);
  address |= fr1 << (0+7+5+5+1+1+2+2);
  address |= (msb(theta + c(0,0,6,6,0)[ring1],7,2)&0x1F) << (0+7+5+5+1+1+2+2+1);
  return address;
}

//std::tuple<int,int,int,int,int,int,int,int,int,int,int,int,int,int> 
std::map<std::string,int> address2predictors15(unsigned int address){
  int dPhi12=0, dPhi23=0, dPhi34=0, dPhi13=0, dPhi14=0, dPhi24=0;
  int dTheta12=0, dTheta23=0, dTheta34=0, dTheta13=0, dTheta14=0, dTheta24=0;
  int theta=0, ring1=0;
  int clct1=0, clct2=0, clct3=0, clct4=0, fr1=0, fr2=0, fr3=0, fr4=0;

  dPhi12 = ((address>>0)&0x7F) << 2;
  dPhi23 = ((address>>(0+7))&0x1F) << 2;
  dPhi34 = ((address>>(0+7+5))&0x1F) << 2;

  unsigned int sPhi23 = (address>>(0+7+5+5))&0x1;
  unsigned int sPhi34 = (address>>(0+7+5+5+1))&0x1;
  dPhi23 *= (sPhi23 ? -1 : 1);
  dPhi34 *= (sPhi34 ? -1 : 1);

  dPhi13 = dPhi12 + dPhi23;
  dPhi14 = dPhi12 + dPhi23 + dPhi34;
  dPhi24 = dPhi23 + dPhi34;

  dTheta12 = 0;
  dTheta23 = 0;
  dTheta34 = 0;
  dTheta13 = 0;
  dTheta24 = 0;
  dTheta14 = (address>>(0+7+5+5+1+1))&0x3;

  clct1 = ((const int[]){3,5,7,10})[(address>>(0+7+5+5+1+1+2))&0x3];
  fr1 = (address>>(0+7+5+5+1+1+2+2))&0x1;

  theta = (address>>(0+7+5+5+1+1+2+2+1))&0x1F;
  ring1 = (theta>50 ? 2 : 1);
  theta = (ring1==2 ? theta-6 : theta);

  std::map<std::string,int> retval;
  retval["dPhi12"] = dPhi12;
  retval["dPhi23"] = dPhi23;
  retval["dPhi34"] = dPhi34;
  retval["dPhi13"] = dPhi13;
  retval["dPhi14"] = dPhi14;
  retval["dPhi24"] = dPhi24;
  retval["dTheta12"] = dTheta12;
  retval["dTheta23"] = dTheta23;
  retval["dTheta34"] = dTheta34;
  retval["dTheta13"] = dTheta13;
  retval["dTheta14"] = dTheta14;
  retval["dTheta24"] = dTheta24;
  retval["theta"] = theta;
  retval["ring1"] = ring1;
  retval["clct1"] = clct1;
  retval["clct2"] = clct2;
  retval["clct3"] = clct3;
  retval["clct4"] = clct4;
  retval["fr1"] = fr1;
  retval["fr2"] = fr2;
  retval["fr3"] = fr3;
  retval["fr4"] = fr4;

  return retval;
//  return std::make_tuple(dPhi12,dPhi23,dPhi34,dTheta12,dTheta23,dTheta34,clct1,clct2,clct3,clct4,fr1,fr2,fr3,fr4);
}
