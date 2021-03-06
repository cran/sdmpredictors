% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/list.R
\name{get_future_layers}
\alias{get_future_layers}
\title{Get the name of future climate layer(s) based on the current climate
layer(s)}
\usage{
get_future_layers(current_layer_codes, scenario, year)
}
\arguments{
\item{current_layer_codes}{character vector. Code(s) of the current climate
layers either as a character vector or as the dataframe provided by
\code{\link{list_layers}}.}

\item{scenario}{character vector. Climate change scenario, e.g. \code{"B1",
"A1B", "A2"}.}

\item{year}{integer. Year for which you want the climate change prediction,
e.g. \code{2100, 2200}.}
}
\value{
A dataframe with information on the future layer(s) matching the
  provided current layer(s).
}
\description{
\code{get_future_layers} returns information on the future climate layers for
the matching current climate layers.
}
\details{
Stops with an exception if no matching future climate layer was
  found for one or more of the provided current climate layer codes.
}
\examples{
future_layers <- get_future_layers(c("BO_salinity", "BO_sstmean"), 
                                   scenario = "B1", year = 2100)
future_layers$layer_code
}
\seealso{
\code{\link{list_layers_future}}, \code{\link{list_layers}},
  \code{\link{load_layers}}
}
