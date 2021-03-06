% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities.r
\encoding{UTF-8}
\name{calc_Fratio}
\alias{calc_Fratio}
\title{calculate F/Ftarget based on F_\%SPR multiplier}
\usage{
calc_Fratio(
  faa,
  waa,
  maa,
  M,
  SPRtarget = 30,
  waa.catch = NULL,
  Pope = TRUE,
  return_SPR = FALSE
)
}
\arguments{
\item{faa}{F at age}

\item{waa}{weight at age}

\item{maa}{maturity at age}

\item{M}{natural morality at age}

\item{SPRtarget}{target SPR (NULLの場合には最適化しない)}

\item{return_SPR}{return SPR as well as Fratio}
}
\description{
calculate F/Ftarget based on F_\%SPR multiplier
}
