% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vali_dates.R
\name{vali_dates}
\alias{vali_dates}
\title{vali_dates}
\usage{
vali_dates(dateStart = NULL, dateEnd = NULL, year = NULL, quietly = TRUE)
}
\arguments{
\item{dateStart}{default is \code{'NULL'}.  This can be a date in the format of 'YYYY-MM-DD' or
'YYYY' (which will then become Jan 1st).}

\item{dateEnd}{default is \code{'NULL'}.  This can be a date in the format of 'YYYY-MM-DD' or
'YYYY' (which will then become Dec 31st).}

\item{year}{default is \code{'NULL'}.}

\item{quietly}{default is \code{TRUE}. When TRUE, no output will be shown.}
}
\description{
This function ensures that functions have valid start and end dates. If only\code{dateStart}
is provided, \code{endDate}  will be for 1 year later. If \code{year} is provided, \code{dateStart}  and
\code{dateEnd} will be Jan 1 and Dec 31 of that year, respectively.
}
\seealso{
Other datesAndTimes: 
\code{\link{simple_date}()}
}
\author{
Mike McMahon, \email{Mike.McMahon@dfo-mpo.gc.ca}
}
\concept{datesAndTimes}
