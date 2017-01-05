#source("train.R")

turnOn <- function(modelFit, threshold = 30, binWidth = 2, shift = 0){
    testSet$res <- predict(modelFit,testSet[,-POI])$predictions

    testSet$bin <- factor( as.integer(1/testSet$muPtGenInv / binWidth ), levels=seq(0,as.integer(100/binWidth),1) )
    tmp <- aggregate( testSet, by=list(bin=testSet$bin), function(x){x} )
    tmp$count   <- unlist(lapply(tmp$res,length))

    tmp$myModel   <- unlist( lapply(tmp$res,function(x){ sum(unlist(x)<1/threshold) }) )
    tmp$reference <- unlist( lapply(tmp$ptTrg,function(x){ sum(unlist(x)-shift>threshold) }) )

    require(reshape2)
    tmp.m <- melt(tmp, id.var = c("bin","count"), measure.vars = c("myModel","reference"))

    turnOn <- tmp.m[,c("bin","count","variable","value")]
    colnames(turnOn) <- c("bin","count","model","countAboveThr")
    turnOn$eff <- with(turnOn,countAboveThr/count)
    turnOn$se  <- with(turnOn,sqrt(eff*(1-eff)/count))
    turnOn$pt  <- with(turnOn,as.integer(bin)*binWidth)

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
