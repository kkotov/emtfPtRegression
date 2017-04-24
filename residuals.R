require("gridExtra")

plot.residuals <- function(results, cutoff = 30, binning = seq(-2,5,0.1), inverse = F){ 

    if( inverse ){
        reference <- data.frame( observable = 1/results$ptTrue,
                                 fitted     = 1/results$refPt,
                                 delta      = with(results, 1/refPt - 1/ptTrue),
                                 deltaRel   = with(results, ptTrue/refPt-1)
                               )
        myModel   <- data.frame( observable = 1/results$ptTrue,
                                 fitted     = 1/results$myPt,
                                 delta      = with(results, 1/myPt - 1/ptTrue),
                                 deltaRel   = with(results, ptTrue/myPt -1)
                               )
        reference <- reference[ reference$observable>1./cutoff, ]
        myModel   <- myModel  [   myModel$observable>1./cutoff, ]
    } else {
        reference <- data.frame( observable = results$ptTrue,
                                 fitted     = results$refPt,
                                 delta      = with(results,  refPt-ptTrue),
                                 deltaRel   = with(results, (refPt-ptTrue)/ptTrue)
                               )
        myModel   <- data.frame( observable = results$ptTrue,
                                 fitted     = results$myPt,
                                 delta      = with(results,  myPt -ptTrue),
                                 deltaRel   = with(results, (myPt -ptTrue)/ptTrue)
                               )
        reference <- reference[ reference$observable<cutoff, ]
        myModel   <- myModel  [   myModel$observable<cutoff, ]
    }

    print( paste("Standard diviation for the reference: ",sd( reference$delta)) )
    print( paste("Standard diviation for my model: ",sd( myModel$delta)) )

    xLabel <- ifelse(inverse,
                     expression((1/p[T] ^{fit} - 1/p[T] ^{true}) / (1/p[T] ^{true})),
                     expression((p[T] ^{fit} - p[T] ^{true}) / p[T] ^{true})
              )

    p1 <- ggplot() +
         geom_histogram(data = reference,
#                        binwidth = binWidth,
                        breaks = binning,
                        alpha = 0.2,
                        aes( x = deltaRel,
                             y = (..count..)/sum(..count..),
                             colour = "r",
                             fill = "r"
                        )
         ) + 
         geom_histogram(data = myModel,
#                        binwidth = binWidth,
                        breaks = binning,
                        alpha = 0.2,
                        aes( x = deltaRel,
                             y = (..count..)/sum(..count..),
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
                             expression(paste("Residuals for the ",1/p[T]," assignment")),
                             expression(paste("Residuals of the ",p[T]," assignment"))
                      )
         ) +
         scale_colour_manual(name = "Models", values=c("r" = "red", "b"="blue"), labels=c("b"="myModel", "r"="reference")) +
         scale_fill_manual(name = "Models",   values=c("r" = "red", "b"="blue"), labels=c("b"="myModel", "r"="reference"))


    p2 <- ggplot() +
         geom_point(data = reference, col="red",  aes(x=observable,y=delta),size=0.01) +
         geom_point(data = myModel,   col="blue", aes(x=observable,y=delta),size=0.01) +
         labs(x = "fitted value",
              y = "fitted - true")



#         scale_fill_manual('Group', breaks = c("myPt","refPt"),
#                               values = c("myPt" = "red", "refPt" = "blue"),
#                               labels = list(expression(italic('x')), expression(italic('y'))) 
#)
#         geom_histogram(binwidth = 0.1, alpha = 0.2,  aes(y=..density.., colour=variable,  fill=variable)) + 
#         theme(legend.position=c(0.85,0.8),  legend.text=element_text(size=15), legend.background = element_rect(fill=alpha('white',0.00001)))
#    require(reshape2)
#    results.m <- melt(results, measure.vars = c("myPt","refPt"))


    grid.arrange(p1,p2)
}
