% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities.r
\encoding{UTF-8}
\name{ref.F}
\alias{ref.F}
\title{再生産関係を仮定しない管理基準値計算(SPR,YPR,F0.1,Fmax)のための関数}
\usage{
ref.F(
  res = NULL,
  Fcurrent = NULL,
  waa = NULL,
  maa = NULL,
  M = NULL,
  waa.catch = NULL,
  M.year = NULL,
  waa.year = NULL,
  maa.year = NULL,
  rps.year = NULL,
  rps.vector = NULL,
  max.age = Inf,
  min.age = 0,
  d = 0.001,
  Fem.init = 0.5,
  Fmax.init = 1.5,
  F0.1.init = 0.7,
  pSPR = seq(10, 90, by = 10),
  iterlim = 1000,
  plot = TRUE,
  Pope = NULL,
  F.range = seq(from = 0, to = 2, length = 101)
)
}
\arguments{
\item{res}{VPAの出力結果(NULLも可)。ここがNULLの場合（VPAの出力結果を与えない場合）でも、Fcurrent, waa, maa, M, waa.catch, max.age, min.age, Popeを別途指定することによって、管理基準値計算ができるようになる}

\item{Fcurrent}{仮定する選択率．NULLの場合，res$Fc.at.ageが使われる}

\item{waa}{仮定する年齢別体重。直接の値を入れるか，waa.yearで年を指定するやり方のどちらでも動く。直接指定するほうが優先。}

\item{maa}{仮定する年齢別成熟率。直接の値を入れるか，waa.yearで年を指定するやり方のどちらでも動く。直接指定するほうが優先。}

\item{M}{仮定する年齢別死亡率。直接の値を入れるか，waa.yearで年を指定するやり方のどちらでも動く。直接指定するほうが優先。}

\item{waa.catch}{仮定する年齢別体重（漁獲量計算用）。直接の値を入れるか，waa.yearで年を指定するやり方のどちらでも動く。直接指定するほうが優先。}

\item{M.year}{年を指定して生物パラメータを仮定する場合．年の範囲の平均値が用いられる．NULLの場合，VPA最終年の値が使われる}

\item{waa.year}{年を指定して生物パラメータを仮定する場合．年の範囲の平均値が用いられる．NULLの場合，VPA最終年の値が使われる}

\item{maa.year}{年を指定して生物パラメータを仮定する場合．年の範囲の平均値が用いられる．NULLの場合，VPA最終年の値が使われる}

\item{rps.year}{Fmedの計算に使うRPSの年の範囲．NULLの場合，全範囲が用いられる}

\item{rps.vector}{Fmedの計算に使うRPSのベクトル。rps.yearよりもこちらが優先される。}

\item{max.age}{加入年齢を０歳としたときに、SPR計算で考慮される最大の年齢（年齢の数ではないことに注意, デフォルトはInf）。加入年齢が１歳以上のときは、SPR計算で考慮したい年齢-加入年齢を入力する、またはmin.ageの引数に加入年齢を設定する。}

\item{min.age}{VPA結果を与える場合にはVPA結果から自動的にもってくるが、VPA結果を与えない場合、加入年齢を入力する}

\item{d}{0.001}

\item{Fem.init}{経験的管理基準値(Fmed, Fmean, Fhigh, Flow)の初期値 (default=0.5)}

\item{Fmax.init}{Fmaxの初期値 (default=1.5)}

\item{F0.1.init}{F0.1の初期値 (default=0.7)}

\item{pSPR}{= seq(10,90,by=10), # F\%SPRを計算するときの％SPR}

\item{iterlim}{}

\item{plot}{結果のプロットを表示するかどうか}

\item{Pope}{Popeの式を使うか}

\item{F.range}{YPR, SPR曲線を書くときのFの範囲（Fの最大値のスケール）、かつ、F\%SPRを計算するときの初期値を決めるために利用される。F\%SPRの推定がうまくいかない場合はこの範囲を調整してください。}
}
\description{
再生産関係を仮定しない管理基準値計算(SPR,YPR,F0.1,Fmax)のための関数
}
\note{
F_SPRのF管理基準値の初期値は　与えられたFのもとでのSPR/目的のSPR　を初期値とするように調整されるので不要。
}
\examples{
data(res_vpa)
# VPAデータを使う場合
res_refF1 <- ref.F(res=res_vpa,Fcurrent=frasyr::apply_year_colum(res_vpa$faa,2015:2017),
                waa.year=2015:2017,maa.year=2015:2017,M.year=2015:2017)

# 生物パラメータをデータとして与える場合
res_refF2 <- ref.F(res=NULL,Fcurrent=rep(0.1,5),
                   waa=rep(100,5),maa=c(0,0,1,1,1),M=rep(0.3,5),waa.catch=rep(100,5),
                   rps.vector=NULL, # Fmedを計算したりする場合のRPSのベクトル.NULLでもOK
                   Pope=TRUE,min.age=0,pSPR=c(30,40))


}
