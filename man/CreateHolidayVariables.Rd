% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CreateHolidayVariables.R
\name{CreateHolidayVariables}
\alias{CreateHolidayVariables}
\title{CreateHolidayVariables Create Holiday Count Columns}
\usage{
CreateHolidayVariables(data, DateCols = "DateTime",
  HolidayGroups = c("USPublicHolidays", "EasterGroup", "ChristmasGroup",
  "OtherEcclesticalFeasts"), Holidays = NULL, GroupingVars = NULL)
}
\arguments{
\item{data}{This is your data}

\item{DateCols}{Supply either column names or column numbers of your date columns you want to use for creating calendar variables}

\item{HolidayGroups}{Pick groups}

\item{Holidays}{Pick holidays}

\item{GroupingVars}{Grouping variable names}
}
\value{
Returns your data.table with the added holiday indicator variable
}
\description{
CreateHolidayVariables Rapidly creates holiday count variables based on the date columns you provide
}
\examples{
\donttest{
data <- data.table::data.table(Date = '2018-01-01 00:00:00')
data <- CreateHolidayVariables(data,
                               DateCols = "DateTime",
                               HolidayGroups = c("USPublicHolidays","EasterGroup",
                                                 "ChristmasGroup","OtherEcclesticalFeasts"),
                               Holidays = NULL,
                               GroupingVars = NULL)
}
}
\seealso{
Other Feature Engineering: \code{\link{AutoDataPartition}},
  \code{\link{AutoTransformationCreate}},
  \code{\link{AutoTransformationScore}},
  \code{\link{AutoWord2VecModeler}},
  \code{\link{CreateCalendarVariables}},
  \code{\link{DT_GDL_Feature_Engineering}},
  \code{\link{DummifyDT}},
  \code{\link{GDL_Feature_Engineering}},
  \code{\link{ModelDataPrep}},
  \code{\link{Partial_DT_GDL_Feature_Engineering}},
  \code{\link{Scoring_GDL_Feature_Engineering}},
  \code{\link{TimeSeriesFill}}
}
\author{
Adrian Antico
}
\concept{Feature Engineering}
