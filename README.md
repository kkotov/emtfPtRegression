## Description

Please, refer to this [python notebook](https://github.com/kkotov/emtfPtRegression/blob/master/ModelSelection.ipynb)
for an insight to this study. The original investigation was performed in R and is
also available for a reference as a series of presentations summarized by the date:
[2017.01.19](https://kkotov.github.io/emtfPtRegression/2017.01.19) 
([single page](https://kkotov.github.io/emtfPtRegression/2017.01.19/handout.html)),
[2017.02.10](https://kkotov.github.io/emtfPtRegression/2017.02.10)
([single page](https://kkotov.github.io/emtfPtRegression/2017.02.10/handout.html)),
[2017.03.03](https://kkotov.github.io/emtfPtRegression/2017.03.03)
([single page](https://kkotov.github.io/emtfPtRegression/2017.03.03/handout.html)),
[2017.03.17](https://kkotov.github.io/emtfPtRegression/2017.03.17)
([single page](https://kkotov.github.io/emtfPtRegression/2017.03.17/handout.html)).

The track pT assignment in the [electronic boards](http://iopscience.iop.org/1748-0221/8/12/C12034)
is done using a fast look-up table (LUT) memory that is filled with the pT values
computed in an offline study of this repository. Thirty bits available for the pT LUT
address encode relative positions of the recorded track segments, bend patters
of individual track segments, and types of these track segments. These are the
very same parameters used as predictors for training the offline regression model
that is used for generating pT values for the LUT. 
