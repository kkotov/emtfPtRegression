## Short description

The [EMTF](http://iopscience.iop.org/1748-0221/8/12/C12034) is one of the custom-built
electronic systems of the CMS Level-1 Trigger (L1T). By means of pattern recognition EMTF
combines multiple track's segments produced by a particle in sensitive regions of the
detector and evaluates track's properties. The most important property, the particle's
momentum (or transverse momentum), is evaluated from track's bending in the inhomogeneous
magnetic field.

The track pT assignment is done with the precomputed values stored in a fast look-up
table (LUT) memory. Thirty bits available for the pT LUT address can encode track's
deflection angles given by relative positions of track segments, bend patters of
individual track segments, as well as other potentially useful track's parameters.

The effect of multiple scattering that affects particle's trajectory renders impossible
analytical calculation of the pT LUT. Instead, the table is constructed using Monte
Carlo simulation and standard machine learning techniques. The best model selection
is based on the application specific metrics (e.g. turn-ons or rate vs. efficiency
curves).

This repository includes a collection of tools for training the pT LUT models and
comparing their performance. Findings are summarized by the date:
[2017.01.19](https://kkotov.github.io/emtfPtRegression/2017.01.19/handout.html),
[2017.02.10](https://kkotov.github.io/emtfPtRegression/2017.01.19/) (incomplete).
