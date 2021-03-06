% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities.r
\name{redo_future}
\alias{redo_future}
\title{re-calculate projection with different arguments}
\usage{
redo_future(
  data_future,
  input_data_list,
  SR_sd = NULL,
  SR_b = NULL,
  only_data = FALSE,
  is_regime = (class(data_future$input$res_SR) == "fit.SRregime"),
  ...
)
}
\description{
re-calculate projection with different arguments
}
