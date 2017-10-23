#include <iostream>
#include <fstream>
#include <tuple>
#include <string>
#include <stdlib.h>
#include <math.h>

#include "DataFrame.h"
#include "RandomForest.h"
#include "csvUtils.h"

// g++ -Wl,--no-as-needed -g -Wall -std=c++11 -o rf rf.cc -lpthread -I/home/kkotov/work/ml

int main(void){
    // data for training and testing
    DataFrame df;

    // input file
    std::ifstream input("one.csv");
    if( !input ) return 0;

    // ignore the first line that is the header
    input.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
    // treat comma as a delimiter
    csvUtils::setCommaDelim(input);

    // specify input format
    std::tuple<float,float,int,float,float,float,float,float,float,float,float,float,float,float,float,float,float,float,float,int,int,int,int,int,int,int,int,int,int,int,int,float,int,float,float> format;
    // and introduce symbolic names for the columns
    const int ptGenInv = 0, theta = 1, st1_ring2 = 2;
    const int dPhi12   = 3, dPhi13   = 4,  dPhi14   = 5,  dPhi23   = 6,  dPhi24   = 7,  dPhi34   = 8;
    const int dTheta12 = 9, dTheta13 = 10, dTheta14 = 11, dTheta23 = 12, dTheta24 = 13, dTheta34 = 14;
    const int dPhiS4 = 15, dPhiS4A = 16, dPhiS3 = 17, dPhiS3A = 18;
    const int clct1 = 19, clct2 = 20, clct3 = 21, clct4 = 22;
    const int fr1   = 23, fr2   = 24, fr3   = 25, fr4   = 26;
    const int rpc1  = 27, rpc2  = 28, rpc3  = 29, rpc4  = 30;
    const int ptXML = 31, trainIdx = 32, ranger = 33, gbm = 34;
 
    // read file to the end
    while( csvUtils::read_tuple(input,format) )
    {
        std::tuple<float,float,int,float,float,float,float,float,float,float,float,float,float,float,float,float,float,float,float,int,int,int,int,int,int,int,int,int,int,int,int,float,int,float,float> row = std::make_tuple(
                1./std::get<ptGenInv>(format),  std::get<theta>(format),  std::get<st1_ring2>(format),
                std::get<dPhi12>(format),    std::get<dPhi13>(format),   std::get<dPhi14>(format),
                std::get<dPhi23>(format),    std::get<dPhi24>(format),   std::get<dPhi34>(format),
                std::get<dTheta12>(format),  std::get<dTheta13>(format), std::get<dTheta14>(format),
                std::get<dTheta23>(format),  std::get<dTheta24>(format), std::get<dTheta34>(format),
                std::get<dPhiS4>(format), std::get<dPhiS4A>(format), std::get<dPhiS3>(format), std::get<dPhiS3A>(format),
                std::get<clct1>(format),  std::get<clct2>(format),   std::get<clct3>(format),  std::get<clct4>(format),
                std::get<fr1>(format),    std::get<fr2>(format),     std::get<fr3>(format),    std::get<fr4>(format),
                std::get<rpc1>(format),   std::get<rpc2>(format),    std::get<rpc3>(format),   std::get<rpc4>(format),
                std::get<ptXML>(format),  std::get<trainIdx>(format),std::get<ranger>(format), std::get<gbm>(format)
        );
        df.rbind( DataRow(row) );
    }
    if( input.bad() )
    {
        std::cerr << "Error: the input file format differs from the described one" << std::endl;
        return 0;
    }

    // countAllLevels has to be called in the end of reading input with categorical variables
    df.countAllLevels();

    std::cout << "Levels of categorical predictors:";
    std::cout << std::endl << " st1_ring2:"; for(auto i: df.getLevels(st1_ring2) ) std::cout << " " << i;
    std::cout << std::endl << " clct1:";     for(auto i: df.getLevels(clct1)     ) std::cout << " " << i;
    std::cout << std::endl << " clct2:";     for(auto i: df.getLevels(clct2)     ) std::cout << " " << i;
    std::cout << std::endl << " clct3:";     for(auto i: df.getLevels(clct3)     ) std::cout << " " << i;
    std::cout << std::endl << " clct4:";     for(auto i: df.getLevels(clct4)     ) std::cout << " " << i;
    std::cout << std::endl << " fr1:";       for(auto i: df.getLevels(fr1)       ) std::cout << " " << i;
    std::cout << std::endl << " fr2:";       for(auto i: df.getLevels(fr2)       ) std::cout << " " << i;
    std::cout << std::endl << " fr3:";       for(auto i: df.getLevels(fr3)       ) std::cout << " " << i;
    std::cout << std::endl << " fr4:";       for(auto i: df.getLevels(fr4)       ) std::cout << " " << i;
    std::cout << std::endl << " rpc1:";      for(auto i: df.getLevels(rpc1)      ) std::cout << " " << i;
    std::cout << std::endl << " rpc2:";      for(auto i: df.getLevels(rpc2)      ) std::cout << " " << i;
    std::cout << std::endl << " rpc3:";      for(auto i: df.getLevels(rpc3)      ) std::cout << " " << i;
    std::cout << std::endl << " rpc4:";      for(auto i: df.getLevels(rpc4)      ) std::cout << " " << i;
    std::cout << std::endl << " trainIdx:";  for(auto i: df.getLevels(trainIdx)  ) std::cout << " " << i;
    std::cout << std::endl << std::endl;

    // split the data frame into training and test data partitions:
    DataFrame dfTrain, dfTest;
    for(size_t row=0; row<df.nrow(); row++)
        if( df[row][trainIdx].asIntegral == 1 ) dfTrain.rbind(df[row]);
        else                                    dfTest. rbind(df[row]);
    dfTrain.countAllLevels();
    dfTest .countAllLevels();

    // train random forest to predict 1/pt using all other predictors
    RandomForest rf1;
    std::vector<unsigned int> predictorsIdx = {theta, st1_ring2, dPhi12, dPhi13, dPhi14, dPhi23, dPhi24, dPhi34,
                 dTheta14, dPhiS4, dPhiS4A, dPhiS3, dPhiS3A, clct1, fr1, rpc1, rpc2, rpc3, rpc4 }; //outStPhi ?

    unsigned int responseIdx = ptGenInv;
    rf1.train(dfTrain,predictorsIdx,responseIdx,500,std::cout);

    // A simple unit test for the IO
    std::ofstream file1("rf3.model");
    rf1.save(file1);
    file1.close();


    std::vector<float> result;
    result.reserve( dfTest.nrow() );
    std::cout << std::endl << "Regression performance: " << std::endl;
    double bias = 0, var = 0;
    long cnt = 0;
    for(unsigned int row = 0; row>=0 && row < dfTest.nrow(); row++,cnt++){
        double prediction = rf1.regress( dfTest[row] );
        double truth      = dfTest[row][responseIdx].asFloating;
        bias +=  prediction - truth;
        var  += (prediction - truth) * (prediction - truth);
        result.push_back(1./prediction);
    }
    double sd = sqrt((var - bias*bias/cnt)/(cnt - 1));
    bias /= cnt;
    std::cout << "bias = "<< bias << " sd = " << sd << std::endl;

    std::vector<float> rownames(dfTest.nrow());
    std::iota(rownames.begin(),rownames.end(),1);
    if( dfTest.cbind(result) && dfTest.cbind(rownames) ) {
        std::ofstream file2("two.csv");
        file2 << dfTest;
        file2.close();
    }

    return 0;
}
