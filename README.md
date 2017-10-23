## Description

Please, refer to this [python notebook](https://github.com/kkotov/emtfPtRegression/blob/master/ModelSelection.ipynb)
for an insight to this study. The original investigation was performed in R and also
available for a reference as a series of presentations summarized by the date:
[2017.01.19](https://kkotov.github.io/emtfPtRegression/2017.01.19) 
([single page](https://kkotov.github.io/emtfPtRegression/2017.01.19/handout.html)),
[2017.02.10](https://kkotov.github.io/emtfPtRegression/2017.02.10)
([single page](https://kkotov.github.io/emtfPtRegression/2017.02.10/handout.html)),
[2017.03.03](https://kkotov.github.io/emtfPtRegression/2017.03.03)
([single page](https://kkotov.github.io/emtfPtRegression/2017.03.03/handout.html)),
[2017.03.17](https://kkotov.github.io/emtfPtRegression/2017.03.17)
([single page](https://kkotov.github.io/emtfPtRegression/2017.03.17/handout.html)).

The track pT assignment in the [electronic boards](http://iopscience.iop.org/1748-0221/8/12/C12034)
is done with the values precomputed using the developed regression models and
stored in a fast look-up table (LUT) memory. Eighteen bits available for the
pT LUT address can encode track's deflection angles given by relative positions
of track segments, bend patters of individual track segments, as well as other
potentially useful track's parameters.

