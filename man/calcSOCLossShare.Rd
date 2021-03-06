% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calcSOCLossShare.R
\name{calcSOCLossShare}
\alias{calcSOCLossShare}
\title{calcSOCLossShare}
\usage{
calcSOCLossShare(subsystems = FALSE, rate = "change", ipcc = "guide2006")
}
\arguments{
\item{subsystems}{if FALSE just generic values will be used per climate zone ,
if TRUE crop specific values will be reported,
if aggregated crop specific factors will be aggregated using crop area}

\item{rate}{if change, change rates will be reported; if loss, loss rates will be reported}

\item{ipcc}{switch for different ipcc versions}
}
\value{
List of magpie objects with results on cellular level, weight, unit and description.
}
\description{
Calculates soil organic carbon loss share on cellular level
}
\examples{

\dontrun{
calcOutput("SOCLossShare", aggregate=FALSE)
}
}
\author{
Kristine Karstens
}
