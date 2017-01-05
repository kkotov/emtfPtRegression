require(ggplot2)
df <- read.csv(file="muonGunPt3_100_Sep2016.csv",header=T,sep=',')
p <- ggplot(data=df,aes(x=jitter(mode.0.),y=muPtGen)) + geom_point()
p <- ggplot(data=df[df[,"mode.0."]==15,],aes(x=dPhi12.0.,y=dPhi23.0.)) + geom_point(shape=1,size=0.1) + geom_smooth(method=lm)
