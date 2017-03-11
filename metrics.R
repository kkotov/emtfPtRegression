# The conventional trigger turn-on curve, constructed with a certain threshold_pT
# in mind, presents the probability that response_pT > threshold_pT as a function
# of true_pT. The main limitation of the turn-on metric is that the model curves
# have to be visually compared for a series of thresholds, which a rather labour-
# intensive exercise. Moreover, such metric also does not offer a good quantitative
# way to account for the prevalence: due to abundance of low true_pT events a sharp
# turn-on with a long left tail may do better as well as do worse compared to wide
# turn-on with a smaller tail. The Receiver Operating Characteristic (ROC) curve
# is free from such limitations, incorporate the prevalence, and can be quantified
# with a simple integral-under-the-curve parameter.
#
# Before introducing the ROC metric let me start with the prevalence and call it
# rate. For some given threshold_pT the convolution of turn-on with the rate in
# the range of [0 < true_pT < threshold_pT] gives a number of false-positive events
# and in the range of [threshold_pT < true_pT < inf] gives true-positives. These
# numbers, normalized by the integrals of the rate in the two regions, give the
# true-/false-positive probabilities. In this scenario the "natural parameter"
# identifying a point on the ROC curve is the threshold_pT. In the code below
# I generate the ROC curve runnig over the grid of threshold_pT defined by the
# binning array.

# simple helper function
findBin <- function(val, binning, start=1, end=length(binning)){
    # Assuming binning is a sorted vector of N bin boundaries
    #  this function returns [1:N-1] bin number
    #  or N - overflow and 0 - underflow
    if( length(binning) < 1 || end < start ) return(-1) # error
    # underflow and overflow goes to the first and last bins
    if( val <  binning[start] ) return(start-1) # underflow
    if( val >= binning[end]   ) return(end)     # overflow
    # partition at the middle element
    center <- as.integer((end-start)/2) + start
    # got lucky
    if( val >= binning[center] && val < binning[center+1] ) return(center)
    # binary search
    if( val < binning[center] )
        return(findBin(val, binning, start, center))
    else 
        return(findBin(val, binning, center+1, end))
}

# calculate the standard turn-ons and rate shape distribution
preprocess <- function(modelFit,
                       testSet,
                       rateShape = data.frame( true_pT=seq(1.5,1000.5,1), trigRate=1/seq(1,1000,1)*1000 ), # example of rate shape
                       binning = seq(0,100,2) # example of binning: pT from 0 to 100 GeV/c in steps of 2 GeV/c
                      )
{
    # first, predict response_pT of the model on the test data
    testSet$res <- 1/predict(modelFit,testSet)$predictions
    # assign every true_pT to a bin
    testSet$trueBin <- sapply(1/testSet$muPtGenInv, findBin, binning)
    # construct a proto-spectrum where every true_pT_bin aggregates response_pT lists
    pSpec <- aggregate(testSet, by=list(bin=testSet$trueBin), function(x) x )
    # a simple histogram of true_pT would be just number of events in every true_pT_bin
    pSpec$count <- sapply(pSpec$res,length)

    # for turn-ons I use the matricies indexed by [true_pT_bin,threshold_pT_bin]
    #  they represent number of events with the response_pT > threshold_pT_bin in every true_pT_bin
    myModelCount   <- t(sapply(pSpec$res,  function(x) sapply(binning,function(y) sum(unlist(x)>y) )))
    referenceCount <- t(sapply(pSpec$ptTrg,function(x) sapply(binning,function(y) sum(unlist(x)>y) )))

    # create a simple histogram from the rateShape
    rateShapeBinned <- sapply( by(rateShape$trigRate, sapply(rateShape$true_pT, findBin, binning), sum), function(x) x )

    # if every event is greater then some low bin boundaries (e.g. aecause pT is positively
    #  defined quantity and we start at 0) add explicitly the underflow bins and set them to 0
    skippedBins <- sum(min(rateShape$true_pT) >= binning)
    rateShapeBinned <- append(rep(0, skippedBins), rateShapeBinned)

    # let's introduce names for the turn-ons 
    myModelTurnOn   <- myModelCount   / pSpec$count
    referenceTurnOn <- referenceCount / pSpec$count

    # the resulting turn-on matrix dimension should be [nBins+1,nBins] i.e. the true_pT bins can underflow
    #  while thresholds are always to count events above
    # if, for example, a negatively defined binning was provided for positively defined pT, add underflow rows
    nBins <- length(binning)
    skippedBins <- min(pSpec$bin) - 1
    if( skippedBins > 0 ){
        myModelTurnOn   <- rbind(matrix(rep(0,nBins*skippedBins),nrow=skippedBins), myModelTurnOn)
        referenceTurnOn <- rbind(matrix(rep(0,nBins*skippedBins),nrow=skippedBins), referenceTurnOn)
    }

    getBinning <- function() binning
    getRateShapeBinned <- function() rateShapeBinned
    getMyTurnOn  <- function() myModelTurnOn
    getRefTurnOn <- function() referenceTurnOn

    list(getBinning = getBinning,
         getRateShapeBinned = getRateShapeBinned,
         getMyTurnOn  = getMyTurnOn,
         getRefTurnOn = getRefTurnOn
    )
}

rocMetric <- function(pp, ...){
    # get precomputed parameters
    rateShapeBinned <- pp$getRateShapeBinned()
    myModelTurnOn   <- pp$getMyTurnOn()
    referenceTurnOn <- pp$getRefTurnOn()
    binning         <- pp$getBinning()

    # normalization integrals
    nBins <- length(binning)
    normForTruePos  <- sapply(1:nBins, function(x) sum(rateShapeBinned[(x:nBins)+1]) )
    normForFalsePos <- sapply(1:nBins, function(x) sum(rateShapeBinned[1:x]) )

    # true-/false-positives are given by a similar convolution over
    # [threshold_pT_bin <= true_pT_bin] / [0 < true_pT_bin < threshold_pT_bin]
    myModelTruePos    <- sapply(1:nBins, function(x) drop(rateShapeBinned[(x:nBins)+1] %*% myModelTurnOn[(x:nBins)+1,x]))
    myModelFalsePos   <- sapply(1:nBins, function(x) drop(rateShapeBinned[1:x] %*% myModelTurnOn[1:x,x]))
    referenceTruePos  <- sapply(1:nBins, function(x) drop(rateShapeBinned[(x:nBins)+1] %*% referenceTurnOn[(x:nBins)+1,x]))
    referenceFalsePos <- sapply(1:nBins, function(x) drop(rateShapeBinned[1:x] %*% referenceTurnOn[1:x,x]))

    # finally, pack everything in one data frame
    myModelROCdf <- data.frame( truePos  = myModelTruePos/normForTruePos,
                                falsePos = myModelFalsePos/normForFalsePos,
                                model    = rep("myModel",nBins)
                    )
    start <- sum(normForFalsePos==0) + 1
    if( start > 1 ) myModelROCdf <- myModelROCdf[start:nBins,]

    referenceROCdf <- data.frame(
                              truePos  = referenceTruePos/normForTruePos,
                              falsePos = referenceFalsePos/normForFalsePos,
                              model    = rep("reference",nBins)
                      )
    if( start > 1 ) referenceROCdf <- referenceROCdf[start:nBins,]

    rocDF <- rbind(myModelROCdf,referenceROCdf)
    rocDF$model <- factor(rocDF$model)

    # ... and plot this data frame
    roc <- ggplot(rocDF, aes(x = truePos, y = falsePos, group = model, colour = model)) + 
#        geom_errorbar(aes(ymin=eff-se, ymax=eff+se), width=.1) +
        geom_line() +
        geom_point() +
        theme(
            title = element_text(size=20),
            axis.title.x = element_text(size=20),
            axis.text.x  = element_text(size=15)
        ) +
        labs( x="true positive",
              y="false positive",
              title="ROC curve"
        ) + scale_y_log10()

    roc
}


# present some of the turn-ons for completeness
turnOns <- function(pp, ...){
    # get precomputed parameters
    rateShapeBinned <- pp$getRateShapeBinned()
    myModelTurnOn   <- pp$getMyTurnOn()
    referenceTurnOn <- pp$getRefTurnOn()
    binning         <- pp$getBinning()

    start <- sum(rateShapeBinned==0) + 1
    nBins <- length(binning)

    turnOns <- list()

    for(threshold in seq(5,30,5)){

        thrBin <- findBin(threshold,binning)

        turnOnDF <-       data.frame(true_pT = binning[start:nBins],
                                     eff    = myModelTurnOn[(start:nBins)+1,thrBin],
                                     thr_pT = threshold,
                                     model  = factor(rep("myModel",nBins-start+1),
                                                     levels=c("myModel","reference")
                                                    )
                                    )

        turnOnDF <- rbind(turnOnDF,
                          data.frame(true_pT = binning[start:nBins]*1.4, # put reference on the same scale
                                     eff    = referenceTurnOn[(start:nBins)+1,thrBin],
                                     thr_pT = threshold,
                                     model  = factor(rep("reference",nBins-start+1),
                                                     levels=c("myModel","reference")
                                                    )
                                    )
                         )

        turnOns[[as.character(threshold)]] <-
            ggplot(turnOnDF, aes(x=true_pT, y=eff, group=model, colour=model)) +
#                geom_errorbar(aes(ymin=eff-se, ymax=eff+se), width=.1) +
                geom_line() +
                geom_point() +
                geom_vline(xintercept = threshold, colour = "red") +
                theme(
                    title = element_text(size=20),
                    axis.title.x = element_text(size=20),
                    axis.text.x  = element_text(size=15)
                ) +
                labs( x=expression(paste(p[T] ^{generator}," (GeV/c)")),
                      y="efficiency",
                      title=bquote("Turn-on (" ~ p[T] ~ ">" ~ .(threshold) ~ " GeV/c)")
                ) + xlim(binning[1], binning[nBins])
    }

    turnOns
}

    # convolution of the rateShape with turn-ons (efficiencies) over all true_pT_bin
#    myModelRate   <- drop(rateShapeBinned %*% myModelTurnOn)
#    referenceRate <- drop(rateShapeBinned %*% referenceTurnOn)


