#' AutoH2oDRFClassifier is an automated H2O modeling framework with grid-tuning and model evaluation
#'
#' AutoH2oDRFClassifier is an automated H2O modeling framework with grid-tuning and model evaluation that runs a variety of steps. First, a stratified sampling (by the target variable) is done to create train and validation sets. Then, the function will run a random grid tune over N number of models and find which model is the best (a default model is always included in that set). Once the model is identified and built, several other outputs are generated: validation data with predictions, evaluation plot, evaluation metrics, variable importance, partial dependence calibration plots, and column names used in model fitting.
#' @author Adrian Antico
#' @family Supervised Learning
#' @param data This is your data set for training and testing your model
#' @param ValidationData This is your holdout data set used in modeling either refine your hyperparameters.
#' @param TestData This is your holdout data set. Catboost using both training and validation data in the training process so you should evaluate out of sample performance with this data set.
#' @param TargetColumnName Either supply the target column name OR the column number where the target is located (but not mixed types). Note that the target column needs to be a 0 | 1 numeric variable.
#' @param FeatureColNames Either supply the feature column names OR the column number where the target is located (but not mixed types)
#' @param eval_metric This is the metric used to identify best grid tuned model. Choose from "AUC" or "logloss"
#' @param Trees The maximum number of trees you want in your models
#' @param GridTune Set to TRUE to run a grid tuning procedure. Set a number in MaxModelsInGrid to tell the procedure how many models you want to test.
#' @param MaxMem Set the maximum amount of memory you'd like to dedicate to the model run. E.g. "32G"
#' @param MaxModelsInGrid Number of models to test from grid options (1080 total possible options)
#' @param model_path A character string of your path file to where you want your output saved
#' @param ModelID A character string to name your model and output
#' @param NumOfParDepPlots Tell the function the number of partial dependence calibration plots you want to create.
#' @param ReturnModelObjects Set to TRUE to output all modeling objects (E.g. plots and evaluation metrics)
#' @param SaveModelObjects Set to TRUE to return all modeling objects to your environment
#' @param IfSaveModel Set to "mojo" to save a mojo file, otherwise "standard" to save a regular H2O model object
#' @examples
#' \donttest{
#' Correl <- 0.85
#' N <- 1000
#' data <- data.table::data.table(Target = runif(N))
#' data[, x1 := qnorm(Target)]
#' data[, x2 := runif(N)]
#' data[, Independent_Variable1 := log(pnorm(Correl * x1 +
#'                                             sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable2 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable3 := exp(pnorm(Correl * x1 +
#'                                             sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable4 := exp(exp(pnorm(Correl * x1 +
#'                                                 sqrt(1-Correl^2) * qnorm(x2))))]
#' data[, Independent_Variable5 := sqrt(pnorm(Correl * x1 +
#'                                              sqrt(1-Correl^2) * qnorm(x2)))]
#' data[, Independent_Variable6 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^0.10]
#' data[, Independent_Variable7 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^0.25]
#' data[, Independent_Variable8 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^0.75]
#' data[, Independent_Variable9 := (pnorm(Correl * x1 +
#'                                          sqrt(1-Correl^2) * qnorm(x2)))^2]
#' data[, Independent_Variable10 := (pnorm(Correl * x1 +
#'                                           sqrt(1-Correl^2) * qnorm(x2)))^4]
#' data[, Independent_Variable11 := as.factor(
#'   ifelse(Independent_Variable2 < 0.20, "A",
#'          ifelse(Independent_Variable2 < 0.40, "B",
#'                 ifelse(Independent_Variable2 < 0.6,  "C",
#'                        ifelse(Independent_Variable2 < 0.8,  "D", "E")))))]
#' data[, ':=' (x1 = NULL, x2 = NULL)]
#' data[, Target := as.factor(ifelse(Independent_Variable2 < 0.5, 1, 0))]
#' TestModel <- AutoH2oDRFClassifier(data,
#'                                   ValidationData = NULL,
#'                                   TestData = NULL,
#'                                   TargetColumnName = "Target",
#'                                   FeatureColNames = 2:ncol(data),
#'                                   eval_metric = "auc",
#'                                   Trees = 50,
#'                                   GridTune = FALSE,
#'                                   MaxMem = "32G",
#'                                   MaxModelsInGrid = 10,
#'                                   model_path = NULL,
#'                                   ModelID = "FirstModel",
#'                                   NumOfParDepPlots = 3,
#'                                   ReturnModelObjects = TRUE,
#'                                   SaveModelObjects = FALSE,
#'                                   IfSaveModel = "mojo")
#' }
#' @return Saves to file and returned in list: VariableImportance.csv, Model, ValidationData.csv, EvalutionPlot.png, EvaluationMetrics.csv, ParDepPlots.R a named list of features with partial dependence calibration plots, GridCollect, and GridList
#' @export
AutoH2oDRFClassifier <- function(data,
                                 ValidationData = NULL,
                                 TestData = NULL,
                                 TargetColumnName = NULL,
                                 FeatureColNames = NULL,
                                 eval_metric = "auc",
                                 Trees = 50,
                                 GridTune = FALSE,
                                 MaxMem = "32G",
                                 MaxModelsInGrid = 2,
                                 model_path = NULL,
                                 ModelID = "FirstModel",
                                 NumOfParDepPlots = 3,
                                 ReturnModelObjects = TRUE,
                                 SaveModelObjects = FALSE,
                                 IfSaveModel = "mojo") {
  # Binary Check Arguments----
  if (!(tolower(eval_metric) %chin% c("auc", "logloss"))) {
    warning("eval_metric not in AUC, logloss")
    
  }
  if (Trees < 1)
    warning("Trees must be greater than 1")
  if (!GridTune %in% c(TRUE, FALSE))
    warning("GridTune needs to be TRUE or FALSE")
  if (MaxModelsInGrid < 1 & GridTune == TRUE) {
    warning("MaxModelsInGrid needs to be at least 1")
  }
  if (!is.null(model_path)) {
    if (!is.character(model_path))
      warning("model_path needs to be a character type")
  }
  if (!is.character(ModelID))
    warning("ModelID needs to be a character type")
  if (NumOfParDepPlots < 0)
    warning("NumOfParDepPlots needs to be a positive number")
  if (!(ReturnModelObjects %in% c(TRUE, FALSE)))
    warning("ReturnModelObjects needs to be TRUE or FALSE")
  if (!(SaveModelObjects %in% c(TRUE, FALSE)))
    warning("SaveModelObjects needs to be TRUE or FALSE")
  if (!(tolower(eval_metric) == "auc")) {
    eval_metric <- tolower(eval_metric)
  } else {
    eval_metric <- toupper(eval_metric)
  }
  if (tolower(eval_metric) %chin% c("auc")) {
    Decreasing <- TRUE
  } else {
    Decreasing <- FALSE
  }
  
  # Binary Target Name Storage----
  if (is.character(TargetColumnName)) {
    Target <- TargetColumnName
  } else {
    Target <- names(data)[TargetColumnName]
  }
  
  # Binary Ensure data is a data.table----
  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }
  
  # Binary Ensure data is a data.table----
  if (!is.null(ValidationData)) {
    if (!data.table::is.data.table(ValidationData)) {
      ValidationData <- data.table::as.data.table(ValidationData)
    }
  }
  
  # Binary Ensure data is a data.table----
  if (!is.null(TestData)) {
    if (!data.table::is.data.table(TestData)) {
      TestData <- data.table::as.data.table(TestData)
    }
  }
  
  # Binary Data Partition----
  if (is.null(ValidationData) & is.null(TestData)) {
    dataSets <- AutoDataPartition(
      data,
      NumDataSets = 3,
      Ratios = c(0.70, 0.20, 0.10),
      PartitionType = "random",
      StratifyColumnNames = Target,
      TimeColumnName = NULL
    )
    data <- dataSets$TrainData
    ValidationData <- dataSets$ValidationData
    TestData <- dataSets$TestData
  }
  
  # Binary ModelDataPrep----
  dataTrain <- ModelDataPrep(data = data,
                             Impute = FALSE,
                             CharToFactor = TRUE)
  
  # Binary ModelDataPrep----
  dataTest <- ModelDataPrep(data = ValidationData,
                            Impute = FALSE,
                            CharToFactor = TRUE)
  
  # Binary ModelDataPrep----
  if (!is.null(TestData)) {
    TestData <- ModelDataPrep(data = TestData,
                              Impute = FALSE,
                              CharToFactor = TRUE)
  }
  
  # Binary Get Min Value of Target Data----
  MinVal <- min(as.numeric(data[[eval(Target)]]), na.rm = TRUE)
  MaxVal <- max(as.numeric(data[[eval(Target)]]), na.rm = TRUE)
  if (MaxVal - MinVal > 1)
    warning("Target Variable is not binary")
  
  # Binary Ensure Target Is a Factor Type----
  if (!is.factor(dataTrain[[eval(Target)]])) {
    dataTrain[, eval(Target) := as.factor(get(Target))]
  }
  
  # Binary Ensure Target Is a Factor Type----
  if (!is.factor(dataTest[[eval(Target)]])) {
    dataTest[, eval(Target) := as.factor(get(Target))]
  }
  
  # Binary Ensure Target Is a Factor Type----
  if (!is.null(TestData)) {
    if (!is.factor(TestData[[eval(Target)]])) {
      TestData[, eval(Target) := as.factor(get(Target))]
    }
  }
  
  # Binary Grid Tune Check----
  if (GridTune) {
    # Binary Start Up H2O----
    h2o::h2o.init(max_mem_size = MaxMem,
                  enable_assertions = FALSE)
    
    # Binary Define data sets----
    datatrain    <- h2o::as.h2o(dataTrain)
    datavalidate <- h2o::as.h2o(dataTest)
    
    # Binary Grid Tune Search Criteria----
    search_criteria  <- list(
      strategy             = "RandomDiscrete",
      max_runtime_secs     = 3600 * 24 * 7,
      max_models           = MaxModelsInGrid,
      seed                 = 1234,
      stopping_rounds      = 10,
      stopping_metric      = eval_metric,
      stopping_tolerance   = 1e-3
    )
    
    # Binary Grid Parameters----
    hyper_params <- list(
      max_depth                        = c(6, 9, 12),
      balance_classes                  = c(TRUE, FALSE),
      sample_rate                      = c(0.5, 0.75, 1.0),
      col_sample_rate_per_tree         = c(0.5, 0.75, 1.0),
      col_sample_rate_change_per_level = c(0.9, 1.0, 1.1),
      min_rows                         = c(1, 5),
      nbins                            = c(10, 20, 30),
      nbins_cats                       = c(64, 256, 512),
      histogram_type                   = c("UniformAdaptive",
                                           "QuantilesGlobal",
                                           "RoundRobin")
    )
    
    # Binary Grid Train Model----
    grid <- h2o::h2o.grid(
      hyper_params         = hyper_params,
      search_criteria      = search_criteria,
      is_supervised        = TRUE,
      algorithm            = "randomForest",
      grid_id              = paste0(ModelID, "_Grid"),
      x                    = FeatureColNames,
      y                    = TargetColumnName,
      ntrees               = Trees,
      training_frame       = datatrain,
      validation_frame     = datavalidate,
      max_runtime_secs     = 3600 * 24 * 7,
      stopping_rounds      = 10,
      stopping_tolerance   = 1e-3,
      stopping_metric      = eval_metric,
      score_tree_interval  = 10,
      seed                 = 1234
    )
    
    # Binary Get Best Model----
    Grid_Out   <- h2o::h2o.getGrid(
      grid_id = paste0(ModelID, "_Grid"),
      sort_by = eval_metric,
      decreasing = Decreasing
    )
    
    # Binary Collect Best Grid Model----
    grid_model <- h2o::h2o.getModel(Grid_Out@model_ids[[1]])
  }
  
  # Binary Start Up H2O----
  if (!GridTune) {
    h2o::h2o.init(max_mem_size = MaxMem,
                  enable_assertions = FALSE)
    
    # Binary Define data sets----
    datatrain    <- h2o::as.h2o(dataTrain)
    datavalidate <- h2o::as.h2o(dataTest)
  }
  
  # Binary Build Baseline Model----
  base_model <- h2o::h2o.randomForest(
    x                = FeatureColNames,
    y                = TargetColumnName,
    training_frame   = datatrain,
    validation_frame = datavalidate,
    model_id         = ModelID,
    ntrees           = Trees
  )
  
  # Binary Get Metrics----
  if (GridTune) {
    if (!is.null(TestData)) {
      datatest        <-  h2o::as.h2o(TestData)
      GridMetrics <- h2o::h2o.performance(model = base_model,
                                          newdata = datatest)
      BaseMetrics <- h2o::h2o.performance(model = base_model,
                                          newdata = datatest)
    } else {
      GridMetrics <- h2o::h2o.performance(model = base_model,
                                          newdata = datavalidate)
      BaseMetrics <- h2o::h2o.performance(model = base_model,
                                          newdata = datavalidate)
    }
  } else {
    if (!is.null(TestData)) {
      datatest        <-  h2o::as.h2o(TestData)
      BaseMetrics <- h2o::h2o.performance(model = base_model,
                                          newdata = datatest)
    } else {
      BaseMetrics <- h2o::h2o.performance(model = base_model,
                                          newdata = datavalidate)
    }
  }
  
  # Binary Evaluate Metrics----
  if (GridTune) {
    if (tolower(eval_metric) == "auc") {
      BaseMetric <- BaseMetrics@metrics$AUC
      GridMetric <- GridMetrics@metrics$AUC
      if (GridMetric > BaseMetric) {
        FinalModel <- grid_model
        EvalMetric <- GridMetric
        FinalThresholdTable <-
          data.table::as.data.table(GridMetrics@metrics$max_criteria_and_metric_scores)
        data.table::setnames(
          FinalThresholdTable,
          c("metric", "threshold", "value"),
          c("Metric", "Threshold", "Value")
        )
        FinalThresholdTable[, idx := NULL]
        FinalThresholdTable[, ':=' (Threshold = round(Threshold, 4),
                                    Value = round(Value, 4))]
      } else {
        FinalModel <- base_model
        EvalMetric <- BaseMetric
        FinalThresholdTable <-
          data.table::as.data.table(BaseMetrics@metrics$max_criteria_and_metric_scores)
        data.table::setnames(
          FinalThresholdTable,
          c("metric", "threshold", "value"),
          c("Metric", "Threshold", "Value")
        )
        FinalThresholdTable[, idx := NULL]
        FinalThresholdTable[, ':=' (Threshold = round(Threshold, 4),
                                    Value = round(Value, 4))]
      }
    } else if (tolower(eval_metric) == "logloss") {
      BaseMetric <- BaseMetrics@metrics$logloss
      GridMetric <- GridMetrics@metrics$logloss
      if (GridMetric < BaseMetric) {
        FinalModel <- grid_model
        EvalMetric <- GridMetric
        FinalThresholdTable <-
          data.table::as.data.table(GridMetrics@metrics$max_criteria_and_metric_scores)
        data.table::setnames(
          FinalThresholdTable,
          c("metric", "threshold", "value"),
          c("Metric", "Threshold", "Value")
        )
        FinalThresholdTable[, idx := NULL]
        FinalThresholdTable[, ':=' (Threshold = round(Threshold, 4),
                                    Value = round(Value, 4))]
      } else {
        FinalModel <- base_model
        EvalMetric <- BaseMetric
        FinalThresholdTable <-
          data.table::as.data.table(BaseMetrics@metrics$max_criteria_and_metric_scores)
        data.table::setnames(
          FinalThresholdTable,
          c("metric", "threshold", "value"),
          c("Metric", "Threshold", "Value")
        )
        FinalThresholdTable[, idx := NULL]
        FinalThresholdTable[, ':=' (Threshold = round(Threshold, 4),
                                    Value = round(Value, 4))]
      }
    }
  } else {
    if (tolower(eval_metric) == "auc") {
      BaseMetric <- BaseMetrics@metrics$AUC
      FinalModel <- base_model
      EvalMetric <- BaseMetric
      FinalThresholdTable <-
        data.table::as.data.table(BaseMetrics@metrics$max_criteria_and_metric_scores)
      data.table::setnames(
        FinalThresholdTable,
        c("metric", "threshold", "value"),
        c("Metric", "Threshold", "Value")
      )
      FinalThresholdTable[, idx := NULL]
      FinalThresholdTable[, ':=' (Threshold = round(Threshold, 4),
                                  Value = round(Value, 4))]
    } else {
      BaseMetric <- BaseMetrics@metrics$logloss
      FinalModel <- base_model
      EvalMetric <- BaseMetric
      FinalThresholdTable <-
        data.table::as.data.table(BaseMetrics@metrics$max_criteria_and_metric_scores)
      data.table::setnames(
        FinalThresholdTable,
        c("metric", "threshold", "value"),
        c("Metric", "Threshold", "Value")
      )
      FinalThresholdTable[, idx := NULL]
      FinalThresholdTable[, ':=' (Threshold = round(Threshold, 4),
                                  Value = round(Value, 4))]
    }
  }
  
  # Binary Save Final Model----
  if (SaveModelObjects) {
    if (tolower(IfSaveModel) == "mojo") {
      SaveModel <- h2o::h2o.saveMojo(object = FinalModel,
                                     path = model_path,
                                     force = TRUE)
      h2o::h2o.download_mojo(
        model = FinalModel,
        path = model_path,
        get_genmodel_jar = TRUE,
        genmodel_path = model_path,
        genmodel_name = ModelID
      )
    } else {
      SaveModel <- h2o::h2o.saveModel(object = FinalModel,
                                      path = model_path,
                                      force = TRUE)
    }
  }
  
  # Binary Score Final Test Data----
  if (!is.null(TestData)) {
    Predict <-
      data.table::as.data.table(h2o::h2o.predict(object = FinalModel,
                                                 newdata = datatest))
    Predict[, p0 := NULL]
    
  } else {
    Predict <-
      data.table::as.data.table(h2o::h2o.predict(object = FinalModel,
                                                 newdata = datavalidate))
    Predict[, p0 := NULL]
  }
  
  # Binary Variable Importance----
  VariableImportance <-
    data.table::as.data.table(h2o::h2o.varimp(object = FinalModel))
  
  # Binary Format Variable Importance Table----
  data.table::setnames(
    VariableImportance,
    c(
      "variable",
      "relative_importance",
      "scaled_importance",
      "percentage"
    ),
    c(
      "Variable",
      "RelativeImportance",
      "ScaledImportance",
      "Percentage"
    )
  )
  VariableImportance[, ':=' (
    RelativeImportance = round(RelativeImportance, 4),
    ScaledImportance = round(ScaledImportance, 4),
    Percentage = round(Percentage, 4)
  )]
  
  # Binary Save Variable Importance----
  if (SaveModelObjects) {
    data.table::fwrite(VariableImportance,
                       file = paste0(model_path,
                                     "/",
                                     ModelID, "_VariableImportance.csv"))
  }
  
  # Binary H2O Shutdown----
  h2o::h2o.shutdown(prompt = FALSE)
  
  # Binary Create Validation Data----
  if (!is.null(TestData)) {
    ValidationData <-
      data.table::as.data.table(cbind(TestData, Predict))
  } else {
    ValidationData <-
      data.table::as.data.table(cbind(dataTest, Predict))
  }
  
  # Binary Change Prediction Name----
  data.table::setnames(ValidationData, "predict", "Predict")
  
  # Binary Save Validation Data to File----
  if (SaveModelObjects) {
    data.table::fwrite(ValidationData,
                       file = paste0(model_path,
                                     "/",
                                     ModelID,
                                     "_ValidationData.csv"))
  }
  
  # Binary Evaluation Calibration Plot----
  EvaluationPlot <- EvalPlot(
    data = ValidationData,
    PredictionColName = "p1",
    TargetColName = Target,
    GraphType = "calibration",
    PercentileBucket = 0.05,
    aggrfun = function(x)
      mean(x, na.rm = TRUE)
  )
  
  # Binary Evaluation Plot Update Title----
  if (GridTune) {
    EvaluationPlot <- EvaluationPlot +
      ggplot2::ggtitle(paste0(
        "Random Forest Calibration Evaluation Plot: ",
        toupper(eval_metric),
        " = ",
        round(EvalMetric, 3)
      ))
  } else {
    EvaluationPlot <- EvaluationPlot +
      ggplot2::ggtitle(paste0(
        "Calibration Evaluation Plot: ",
        toupper(eval_metric),
        " = ",
        round(EvalMetric, 3)
      ))
  }
  
  # Binary Save plot to file----
  if (SaveModelObjects) {
    ggplot2::ggsave(paste0(model_path,
                           "/",
                           ModelID,
                           "_EvaluationPlot.png"))
  }
  
  # Binary AUC Object Create----
  AUC_Metrics <-
    pROC::roc(
      response = ValidationData[[eval(Target)]],
      predictor = ValidationData[["p1"]],
      na.rm = TRUE,
      algorithm = 3,
      auc = TRUE,
      ci = TRUE
    )
  
  # Binary AUC Conversion to data.table----
  AUC_Data <- data.table::data.table(
    ModelNumber = 0,
    Sensitivity = AUC_Metrics$sensitivities,
    Specificity = AUC_Metrics$specificities
  )
  
  # Binary Plot ROC Curve----
  ROC_Plot <-
    ggplot2::ggplot(AUC_Data, ggplot2::aes(x = 1 - Specificity)) +
    ggplot2::geom_line(ggplot2::aes(y = AUC_Data[["Sensitivity"]]), color = "blue") +
    ggplot2::geom_abline(slope = 1, color = "black") +
    ggplot2::ggtitle(paste0("RandomForest AUC: ",
                            100 * round(AUC_Metrics$auc, 3), "%")) +
    ChartTheme() + ggplot2::xlab("Specificity") +
    ggplot2::ylab("Sensitivity")
  
  # Save plot to file
  if (SaveModelObjects) {
    ggplot2::ggsave(paste0(model_path,
                           "/",
                           ModelID,
                           "_ROC_Plot.png"))
  }
  
  # Binary Save EvaluationMetrics to File----
  if (SaveModelObjects) {
    data.table::fwrite(FinalThresholdTable,
                       file = paste0(model_path,
                                     "/",
                                     ModelID,
                                     "_EvaluationMetrics.csv"))
  }
  
  # Binary Partial Dependence----
  ParDepPlots <- list()
  j <- 0
  for (i in seq_len(min(length(FeatureColNames), NumOfParDepPlots))) {
    tryCatch({
      Out <- ParDepCalPlots(
        data = ValidationData,
        PredictionColName = "p1",
        TargetColName = Target,
        IndepVar = VariableImportance[i, Variable],
        GraphType = "calibration",
        PercentileBucket = 0.05,
        FactLevels = 10,
        Function = function(x)
          mean(x, na.rm = TRUE)
      )
      
      j <- j + 1
      ParDepPlots[[paste0(VariableImportance[j, Variable])]] <-
        Out
    }, error = function(x)
      "skip")
  }
  
  # Binary Save ParDepPlots to file----
  if (SaveModelObjects) {
    save(ParDepPlots,
         file = paste0(model_path, "/", ModelID, "_ParDepPlots.R"))
  }
  
  # Binary Return Objects----
  if (ReturnModelObjects) {
    return(
      list(
        Model = FinalModel,
        ValidationData = ValidationData,
        ROC_Plot = ROC_Plot,
        EvaluationPlot = EvaluationPlot,
        EvaluationMetrics = FinalThresholdTable,
        VariableImportance = VariableImportance,
        PartialDependencePlots = ParDepPlots
      )
    )
  }
}