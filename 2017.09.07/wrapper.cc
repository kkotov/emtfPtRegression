#include "DataFrame.h"
#include "RandomForest.h"
#include "csvUtils.h"
#include <iostream>
#include <fstream>

// g++ -Wl,--no-as-needed -fPIC -g -Wall -std=c++11 -c wrapper.cc -lpthread -I/home/kkotov/ml/
// g++ -shared wrapper.o -o wrapper.so

using namespace std;

extern "C" {
    RandomForest* RandomForest_new(void){
        return new RandomForest;
    }
    void RandomForest_load(RandomForest *rf, const char *filename){
        ifstream file(filename);
        rf->load(file);
        file.close();
    }
    double RandomForest_regress(RandomForest *rf,
int theta, int st1_ring2,
int dPhi12, int dPhi13, int  dPhi14, int dPhi23, int dPhi24, int dPhi34,
int dTheta14,
int dPhiS4, int dPhiS4A, int dPhiS3, int dPhiS3A,
int clct1,
int fr1,
int rpc1, int rpc2, int rpc3, int rpc4
){
        DataRow row(tuple<float,int,float,float,float,float,float,float,float,float,float,float,float,int,int,int,int,int,int>(
theta, st1_ring2,
dPhi12, dPhi13,  dPhi14,  dPhi23,  dPhi24,  dPhi34,
dTheta14,
dPhiS4, dPhiS4A, dPhiS3, dPhiS3A,
clct1,
fr1,
rpc1, rpc2, rpc3, rpc4
)); 
        return rf->regress(row);
    }
}
