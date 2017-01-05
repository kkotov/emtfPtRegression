delta <- function(modelFit, binning = seq(-2,5,0.1), inverse=F){ 
    results <- data.frame( ptTrue = 1/testSet$muPtGenInv,
                           myPt   = 1/predict(modelFit,testSet[,-POI])$predictions,
                           refPt  = testSet[,"ptTrg"]
               )

    if( inverse ){
        reference <- data.frame( delta = with(results, ptTrue/refPt-1) )
        myModel   <- data.frame( delta = with(results, ptTrue/myPt -1) )
    } else {
        reference <- data.frame( delta = with(results, (refPt-ptTrue)/ptTrue) )
        myModel   <- data.frame( delta = with(results, (myPt -ptTrue)/ptTrue) )
    }

    print( paste("Standard diviation for the reference: ",sd( reference$delta)) )
    print( paste("Standard diviation for my model: ",sd( myModel$delta)) )

    xLabel <- ifelse(inverse,
                     expression((1/p[T] ^{predict} - 1/p[T] ^{true}) / 1/p[T] ^{true}),
                     expression((p[T] ^{predict} - p[T] ^{true}) / p[T] ^{true})
              )

    ggplot() +
         geom_histogram(data = reference,
#                        binwidth = binWidth,
                        breaks = binning,
                        alpha = 0.2,
                        aes( x = delta,
#                             y = (..count..)/sum(..count..),
                             colour = "r",
                             fill = "r"
                        )
         ) + 
         geom_histogram(data = myModel,
#                        binwidth = binWidth,
                        breaks = binning,
                        alpha = 0.2,
                        aes( x = delta,
#                             y = (..count..)/sum(..count..),
                             colour = "b",
                             fill = "b"
                        )
         ) +
         theme(title = element_text(size=20),
               axis.title.x = element_text(size=20),
               axis.text.x = element_text(size=15)
         ) +
         labs(x = xLabel,
              y = "density",
              title = ifelse(inverse,
                             expression(paste("Accuracy of the ",1/p[T]," assignment")),
                             expression(paste("Accuracy of the ",p[T]," assignment"))
                      )
         ) +
         scale_colour_manual(name = "Models", values=c("r" = "red", "b"="blue"), labels=c("b"="myModel", "r"="reference")) +
         scale_fill_manual(name = "Models",   values=c("r" = "red", "b"="blue"), labels=c("b"="myModel", "r"="reference"))

#         scale_fill_manual('Group', breaks = c("myPt","refPt"),
#                               values = c("myPt" = "red", "refPt" = "blue"),
#                               labels = list(expression(italic('x')), expression(italic('y'))) 
#)
#         geom_histogram(binwidth = 0.1, alpha = 0.2,  aes(y=..density.., colour=variable,  fill=variable)) + 
#         theme(legend.position=c(0.85,0.8),  legend.text=element_text(size=15), legend.background = element_rect(fill=alpha('white',0.00001)))
#    require(reshape2)
#    results.m <- melt(results, measure.vars = c("myPt","refPt"))
}
