% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ModelDataPrep.R
\name{ModelDataPrep}
\alias{ModelDataPrep}
\title{Final Data Preparation Function}
\usage{
ModelDataPrep(data, Impute = TRUE, CharToFactor = TRUE,
  IntToNumeric = TRUE, RemoveDates = FALSE, MissFactor = "0",
  MissNum = -1, IgnoreCols = NULL)
}
\arguments{
\item{data}{This is your source data you'd like to modify}

\item{Impute}{Defaults to TRUE which tells the function to impute the data}

\item{CharToFactor}{Defaults to TRUE which tells the function to convert characters to factors}

\item{IntToNumeric}{Defaults to TRUE which tells the function to convert integers to numeric}

\item{RemoveDates}{Defaults to FALSE. Set to TRUE to remove date columns from your data.table}

\item{MissFactor}{Supply the value to impute missing factor levels}

\item{MissNum}{Supply  the value to impute missing numeric values}

\item{IgnoreCols}{Supply column numbers for columns you want the function to ignore}
}
\value{
Returns the original data table with corrected values
}
\description{
This function replaces inf values with NA, converts characters to factors, and imputes with constants
}
\examples{
data <- data.table::data.table(Value = runif(100000),
                               FactorCol = as.character(sample(x = c(letters,
                                                                     LETTERS,
                                                                     paste0(letters,letters),
                                                                     paste0(LETTERS,LETTERS),
                                                                     paste0(letters,LETTERS),
                                                                     paste0(LETTERS,letters)),
                                                               size = 100000,
                                                               replace = TRUE)))
data <- ModelDataPrep(data,
                      Impute = TRUE,
                      CharToFactor = TRUE,
                      IntToNumeric = TRUE,
                      MissFactor = "0",
                      MissNum    = -1)
}
\seealso{
Other Feature Engineering: \code{\link{AutoDataPartition}},
  \code{\link{AutoTransformationCreate}},
  \code{\link{AutoTransformationScore}},
  \code{\link{AutoWord2VecModeler}},
  \code{\link{CreateCalendarVariables}},
  \code{\link{CreateHolidayVariables}},
  \code{\link{DT_GDL_Feature_Engineering}},
  \code{\link{DummifyDT}},
  \code{\link{GDL_Feature_Engineering}},
  \code{\link{Partial_DT_GDL_Feature_Engineering}},
  \code{\link{Scoring_GDL_Feature_Engineering}},
  \code{\link{TimeSeriesFill}}
}
\author{
Adrian Antico
}
\concept{Feature Engineering}
