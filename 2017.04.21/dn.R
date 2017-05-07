model_10 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(10), epochs = 500)

model_50 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(50), epochs = 500)

model_100 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(100), epochs = 500)

model_150 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(150), epochs = 500)

model_250 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(250), epochs = 500)

model_10_10 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(10,10), epochs = 500)

model_50_10 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(50,10), epochs = 500)

model_50_50  <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(50,50), epochs = 500)

model_100_50 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(100,50), epochs = 500)

model_100_100 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(100,100), epochs = 500)

model_250_250 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(250,250), epochs = 500)

model_10_10_10  <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(10,10,10), epochs = 500)

model_50_10_10  <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(50,10,10), epochs = 500)

model_50_50_10 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(50,50,10), epochs = 500)

model_50_50_50 <- h2o.deeplearning(x=c(3:14), y=1, nfolds=10, keep_cross_validation_predictions = T, keep_cross_validation_fold_assignment = T, training_frame = train, validation_frame = valid, input_dropout_ratio = 0.2, hidden = c(50,50,50), epochs = 500)


model_10@model$cross_validation_metrics_summary["rmse",]

model_50@model$cross_validation_metrics_summary["rmse",]

model_100@model$cross_validation_metrics_summary["rmse",]

model_150@model$cross_validation_metrics_summary["rmse",]

model_10_10@model$cross_validation_metrics_summary["rmse",]

model_50_10@model$cross_validation_metrics_summary["rmse",]

model_50_50@model$cross_validation_metrics_summary["rmse",]

model_10_10_10@model$cross_validation_metrics_summary["rmse",]

model_50_10_10@model$cross_validation_metrics_summary["rmse",]

model_50_50_10@model$cross_validation_metrics_summary["rmse",]

model_50_50_50@model$cross_validation_metrics_summary["rmse",]

h2o.saveModel(model_10,"model_10")

#...

testSet7 <- as.data.frame(test)
source("roc.R")
roc(testSet7, as.data.frame( h2o.predict(model_50_50,test) ))

plot.residuals(data.frame( ptTrue=1/testSet7$muPtGenInv, refPt=testSet7$ptTrg, myPt=1/as.data.frame(h2o.predict(model_50_50,test))$predict), inverse=T)
