require(reshape2)

findBin <- function(val, binning, start=1, end=length(binning)){
    # assuming _binning_ is a sorted vector of N bin boundaries
    #  this function returns [1:N-1] bin number or N - overflow and 0 - underflow
    if( length(binning) < 1 || end < start ) return(-1) # error
    # underflow and overflow goes to the first and last bins
    if( val <= binning[start] ) return(start-1) # underflow
    if( val >= binning[end]   ) return(end)     # overflow
    # partition at the middle element
    center <- as.integer((end-start)/2) + start
    # got lucky
    if( val >= binning[center] && val <= binning[center+1] ) return(center)
    # binary search
    if( val <= binning[center] )
        return(findBin(val, binning, start, center))
    else 
        return(findBin(val, binning, center+1, end))
}

metrics <- function(modelFit,
                    testSet,
                    rateShape = data.frame( true_pT=seq(1,1000,1), trigRate=1/seq(1,1000,1)*1000 ), # example of rate shape
                    binning = seq(0,100,2) # example of binning: pT from 0 to 100 GeV/c in steps of 2 GeV/c
                   )
{
    # first, predict responce_pT of the model (ranger in this case) on test data
    testSet$res <- 1/predict(modelFit,testSet)$predictions
    # assign every true_pT to a bin
    testSet$trueBin <- findBin(1/testSet$muPtGenInv, binning)
    # construct a proto-spectrum where every true_pT_bin aggregates responce_pT lists
    pSpec <- aggregate(testSet, by=list(bin=testSet$trueBin), function(x){x})
    # a simple histogram of true_pT would be just number of events in every true_pT_bin
    pSpec$count <- sapply(pSpec$res,length)

    # now run threshold pT over the grid of binning

    # efficiency part: events with the responce_pT over the threshold count towards efficiency
    # the matrices below are indexed by [pT_bin,true_pT_bin] and represent number of events with the responce_pT > pT_bin
    pSpec$myModel   <- sapply(pSpec$res,  function(x){ sapply(binning,function(y){ sum(unlist(x)>y) })})
    pSpec$reference <- sapply(pSpec$ptTrg,function(x){ sapply(binning,function(y){ sum(unlist(x)>y) })})

    # the sharpness of turn-on can be achieved by:
    #  1. minimising efficiency[ pT_bin < true_pT_bin, for all true_pT_bin ] (false-positives %)
    #  2. maximizing efficiency[ pT_bin > true_pT_bin, for all true_pT_bin ] (true-positives %)
    # although, with the matrices above it is now straitforward to construct conventional
    #  ROC curves, this would give us a misleading metric because not all false-positives
    #  have the same prise: accidently promoting true_pT of 5 GeV to 30 GeV (above some threshold)
    #  is much worse than promoting true_pT of 10 GeV because there is ~10 times more 5 GeV events
    # hence, a sharp turn-on with a long left tail in ROC metric would do seemingly better that
    #  wide turn-on with no tail, but in practice first would saturate the trigger bandwidth
    # this is why we rather construct efficiency/rate (true-positive % / realistic true+false positive count)
    #  metric

    # rate part: to have a realistic trigger count I convolute the rateShape with turn-on curve
    turnOn <- melt(pSpec,
                   id.var = c("trueBin","count"),
                   measure.vars = c("myModel","reference")
                  )[,c("trueBin","count","variable","value")]
    colnames(turnOn) <- c("trueBin","count","model","countsAboveThresholds")

    turnOn$eff <- with(turnOn,countsAboveThresholds/count)
    turnOn$se  <- with(turnOn,sqrt(eff*(1-eff)/count))
    turnOn$pt  <- with(turnOn,binning[trueBin])

rateShape = data.frame( true_pT=seq(1,1000,1), trigRate=1/seq(1,1000,1)*1000 )

    rateShapeBinned <- apply(rateShape,1,function(x){x["true_pT"]})

    testSet$resBin  <- findBin(1/testSet$res, binning)
    testSet$refBin  <- findBin(testSet$ptTrg, binning)

        testSet$resFire <- with(testSet, resBin >= trueBin)
        testSet$refFire <- with(testSet, refBin >= trueBin)

    tmp <- aggregate( testSet, by=list(trueBin=testSet$trueBin), function(x){x} )
    tmp$count <- sapply(tmp$res,length)

    tmp$myModel   <- sapply(tmp$resFire, length)
    tmp$reference <- sapply(tmp$refFire, length)

    require(reshape2)
    tmp.m <- melt(tmp, id.var = c("bin","count"), measure.vars = c("myModel","reference"))

    turnOn <- tmp.m[,c("bin","count","variable","value")]
    colnames(turnOn) <- c("bin","count","model","countMatches")
    turnOn$eff <- with(turnOn,countMatches/count)
    turnOn$se  <- with(turnOn,sqrt(eff*(1-eff)/count))
    turnOn$pt  <- with(turnOn, as.integer(bin)*binWidth )

    ggplot(turnOn, aes(x = pt, y = eff, group = model, colour = model)) + 
        geom_errorbar(aes(ymin=eff-se, ymax=eff+se), width=.1) +
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
        )

}
