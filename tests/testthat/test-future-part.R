library(frasyr)
context("check future_vpa with sample data") # マアジデータでの将来予測 ----

data(res_vpa)
data(res_sr_HSL2)

# normal lognormal ----
data_future_test <- make_future_data(res_vpa, # VPAの結果
                                     nsim = 100, # シミュレーション回数
                                     nyear = 20, # 将来予測の年数
                                     future_initial_year_name = 2017, 
                                     start_F_year_name = 2018, 
                                     start_biopar_year_name=2018, 
                                     start_random_rec_year_name = 2018,
                                     # biopar setting
                                     waa_year=2015:2017, waa=NULL, 
                                     waa_catch_year=2015:2017, waa_catch=NULL,
                                     maa_year=2015:2017, maa=NULL,
                                     M_year=2015:2017, M=NULL,
                                     # faa setting
                                     faa_year=2015:2017, 
                                     currentF=NULL,futureF=NULL, 
                                     # HCR setting (not work when using TMB)
                                     start_ABC_year_name=2019, # HCRを適用する最初の年
                                     HCR_beta=1, # HCRのbeta
                                     HCR_Blimit=-1, # HCRのBlimit
                                     HCR_Bban=-1, # HCRのBban
                                     HCR_year_lag=0, # HCRで何年遅れにするか
                                     HCR_function_name = "HCR_default",
                                     # SR setting
                                     res_SR=res_sr_HSL2, 
                                     seed_number=1, 
                                     resid_type="lognormal", 
                                     resample_year_range=0, # リサンプリングの場合、残差をリサンプリングする年の範囲
                                     bias_correction=TRUE, # バイアス補正をするかどうか
                                     recruit_intercept=0, # 移入や放流などで一定の加入がある場合に足す加入尾数
                                     # Other
                                     Pope=res_vpa$input$Pope,
                                     fix_recruit=list(year=c(2020,2021),rec=c(1000,2000)),
                                     fix_wcatch=list(year=c(2020,2021),wcatch=c(1000,2000))
                                     )

test_that("future_vpa function (with sample vpa data) (level 2)",{
  # check SD0
  x <- test_sd0_future(data_future_test)
  res_future_test <- x[[1]]
  expect_equal(x[[3]],0,tol=0.005)
  
  # check MSE option(時間かかるので省略。通るはず。
  #  x <- check_MSE_sd0(data_future_test, nsim_for_check = 1000)[1:3] %>% as.numeric()
  #  expect_equal(x,c(0,0,1),tol=0.005)
  
  # option fix_recruit、fix_wcatchのチェック
  catch <- apply(res_future_test$wcaa,c(2,3),sum)
  expect_equal(mean(res_future_test$naa[1,"2020",]), 1000)
  expect_equal(mean(catch["2020",]), 1000, tol=0.001)
  expect_equal(mean(catch["2021",]), 2000, tol=0.001)  
  # beta=0の場合でもwcatchを優先させる
  res_future_test <- redo_future(data_future_test, list(HCR_beta=0, fix_recruit=NULL,start_ABC_year_name=2020, nyear=5))
  catch <- apply(res_future_test$wcaa,c(2,3),sum)
  expect_equal(mean(catch["2020",]), 1000, tol=0.001)
  expect_equal(mean(catch["2021",]), 2000, tol=0.001)
  expect_equal(mean(catch["2022",]), 0, tol=0.001)
  

  # backward-resamplingの場合 ----
  data_future_backward <- redo_future(data_future_test,
                                      list(resid_type="backward", # 加入の誤差分布（"lognormal": 対数正規分布、"resample": 残差リサンプリング）
                                          resample_year_range=0, # リサンプリングの場合、残差をリサンプリングする年の範囲
                                          backward_duration=5,
                                          bias_correction=TRUE),
                                      only_data=TRUE)

  res_future_backward <- future_vpa(tmb_data=data_future_backward$data,
                                    optim_method="none",
                                    multi_init = 1)
  # option fix_recruit、fix_wcatchのチェック
  expect_equal(mean(res_future_backward$naa[1,"2020",]), 1000)
  catch <- apply(res_future_backward$wcaa,c(2,3),sum)
  expect_equal(mean(catch["2020",]), 1000, tol=0.001)
  expect_equal(mean(catch["2021",]), 2000, tol=0.001)

  # future_vpaに追加したオプション（max_F, max_exploitation_rateの確認）
  small_maxF <- 0.001
  expect_warning(res_future_test2 <- redo_future(data_future_test,
                                                 list(max_F=small_maxF),
                                                 optim_method="none",
                                                 multi_init = 1))
  expect_equal(round(max(res_future_test2$faa[,"2020",1])/small_maxF,3),1)

  expect_warning(res_future_test3 <-
                     redo_future(data_future_test,
                                 list(fix_wcatch=list(year=c(2020,2021),wcatch=c(100000,200000)),
                                      max_exploitation_rate=0.8),
                                 optim_method="none", multi_init = 1, )
                 )

  # MSY計算の場合 (対数正規分布) ----
  res_future_test_R <- future_vpa(tmb_data=data_future_test$data,
                                  optim_method="R",
                                  multi_init  = 1,
                                  multi_lower = 0.001, multi_upper = 5,
                                  objective="MSY")
  # [1] 0.5269326
  #expect_equal(round(res_future_test_R$multi,3),0.527)
  # 1000回だと0.527, 100回だと0.537
  expect_equal(round(res_future_test_R$multi,3),0.537)

  # MSY計算の場合 (バックワード)
  res_future_test_backward <- future_vpa(tmb_data=data_future_backward$data,
                                  optim_method="R",
                                  multi_init  = 1,
                                  multi_lower = 0.001, multi_upper = 5,
                                  objective="MSY")
  # 1000回で0.525, 100回で0.519
  #expect_equal(round(res_future_test_backward$multi,3),0.525)
  expect_equal(round(res_future_test_backward$multi,3),0.519)


  if(sum(installed.packages()[,1]=="TMB")){
      # res_future_test_tmb <- future_vpa(tmb_data=data_future_test$data,
      #                                  optim_method="tmb",
      #                                  multi_init  = 1,
      #                                  multi_lower = 0.001, multi_upper = 5,
      #                                  objective="MSY")
      # expect_equal(round(res_future_test_tmb$multi,3),0.527)
  }

})

test_that("future_vpa function (yerly change of beta, Blimit and Bban) (level 2)",{ # ----

  specific_beta <- 0.5

  data_future_test <- redo_future(data_future_test,
                                  list(nsim=10,nyear=10,HCR_beta_year = tibble(year=2021:2023,beta=rep(specific_beta,3)),
                                       fix_recruit=NULL,fix_wcatch=NULL),
                                  only_data=TRUE)

  expect_equal(as.numeric(apply(data_future_test$data$HCR_mat[,,"beta"],1,mean)[c("2021","2023")]),
               rep(specific_beta,2))

  res_future <- future_vpa(tmb_data=data_future_test$data,
                           optim_method="none",
                           multi_init = 1,SPRtarget=0.3)

  expect_equal(as.numeric(apply(res_future$HCR_mat[,,"beta"],1,mean)[c("2021","2023")]),
               rep(specific_beta,2))

  res_bs <- beta.simulation(res_future$input,beta_vector=c(0.8,1),type="new",
                            year_beta_change=2024:2100)

  res_bs %>% dplyr::filter(stat=="Fratio" & year>2020 & year < 2025) %>%
      group_by(beta,year) %>% summarise(mean=mean(value)) %>%
      ungroup()  %>%
      select(mean)  %>%
      round(3) %>% unlist() %>% as.numeric() %>%
      expect_equal(c(rep(0.072,3),0.115,rep(0.072,3),0.143))

  #flexible HCR
  HCR_specific <<- function(ssb, Blimit, Bban, beta, year_name){
      return(0)
  }

  res_future_myHCR <- data_future_test$data %>%
      list_modify(HCR_function_name="HCR_specific",nsim=10) %>%
      future_vpa(optim_method="none")

  expect_equal(all(res_future_myHCR$faa[,as.character(2019:2027),]==0),TRUE)

  ## yearly Blimit
  Blimit_setting <- tibble(year=2021:2023,Blimit=0)
  res_future <- redo_future(data_future_test,
                            list(nsim=10,
                                 HCR_Blimit=1000,HCR_Blimit_year=Blimit_setting))

  x <- apply(res_future$HCR_mat[as.character(Blimit_setting$year),,"Blimit"],1,mean) %>%
      unlist()  %>% as.numeric()
  expect_equal(x, as.numeric(unlist(Blimit_setting$Blimit)))

  ## yearly Bban
  Bban_setting <- tibble(year=2021:2023,Bban=0)
  res_future <- redo_future(data_future_test,
                            list(nsim=10,
                                 HCR_Bban=1000,HCR_Bban_year=Bban_setting))

  x <- apply(res_future$HCR_mat[as.character(Bban_setting$year),,"Bban"],1,mean) %>%
      unlist()  %>% as.numeric()
  expect_equal(x, as.numeric(unlist(Bban_setting$Bban)))

  ## upper limit of catch CV
  CV_range <- c(0.85,1.1)
  res_future <- redo_future(data_future_test,
                            list(nsim=10,nyear=7,
                                 HCR_TAC_upper_CV=CV_range[2],
                                 HCR_TAC_lower_CV=CV_range[1]),
                            do_MSE=FALSE)
  x <- round(res_future$HCR_realized[-1,,"wcatch"]/res_future$HCR_realized[-nrow(res_future$HCR_realized[-1,,"wcatch"]),,"wcatch"],2)
  expect_equal(range(x[as.character(2019:2023),]),CV_range)

  res_future <- redo_future(data_future_test,
                            list(nsim=10,nyear=7,
                                 HCR_TAC_upper_CV=tibble(year=2019:2021,TAC_upper_CV=CV_range[2]),
                                 HCR_TAC_lower_CV=tibble(year=2019:2021,TAC_lower_CV=CV_range[1])),
                            do_MSE=FALSE)
  x <- round(res_future$HCR_realized[-1,,"wcatch"]/res_future$HCR_realized[-nrow(res_future$HCR_realized[-1,,"wcatch"]),,"wcatch"],2)
  expect_equal(range(x[as.character(2019:2020),]),CV_range)
  expect_equal(range(x[as.character(2021:2023),]),c(0.58,1.87))

  data_future <- redo_future(data_future_test,
                             list(nsim=10,nyear=7,
                                  HCR_TAC_upper_CV=tibble(year=2019:2021,TAC_upper_CV=CV_range[2]),
                                  HCR_TAC_lower_CV=tibble(year=2019:2021,TAC_lower_CV=CV_range[1])),
                             only_data=TRUE)
  #  check_MSE_sd0(data_future, nsim_for_check = 5000)[1:3] %>% as.numeric()
  # 1,2 はOK。3も大丈夫そうなのに、2％くらいずれる、、。

})

test_that("future_vpa function (MSE) (level 2)",{ # ----

  data_future_test10 <- redo_future(data_future_test,
                                    list(nsim=10,nyear=10,
                                         fix_recruit=NULL,fix_wcatch=NULL),
                                    only_data=TRUE)

  data_future_test1000 <- redo_future(data_future_test,
                                    list(nsim=1000,nyear=10,
                                         fix_recruit=NULL,fix_wcatch=NULL),
                                    only_data=TRUE)  
  

  # 1000回のノーマル将来予測
  res_future_noMSE <- future_vpa(tmb_data=data_future_test1000$data,
                           optim_method="none",
                           multi_init = 1,SPRtarget=0.3,
                           do_MSE=FALSE, MSE_input_data=data_future_test1000)

  # 10回のシミュレーションでそれぞれ1000回の将来予測をやってTACを計算する
  res_future_MSE <- future_vpa(tmb_data=data_future_test10$data,
                           optim_method="none",
                           multi_init = 1,SPRtarget=0.3,
                           do_MSE=TRUE, MSE_input_data=data_future_test10,MSE_nsim=1000)

  # 以前の計算と同じ結果が出るかのテスト
  expect_equal(round(mean(get_wcatch(res_future_noMSE)["2019",])),32311) 
  expect_equal(round(mean(get_wcatch(res_future_MSE)["2019",])),32370)

  check_MSE_sd0(data_future_test10, nsim_for_check = 1000)

})


test_that("future_vpa function (carry over TAC) (level 2)",{

  data_future_test <- redo_future(data_future_test,
                                  list(nsim=10,nyear=10,
                                       HCR_TAC_reserve_rate=0.1,
                                       HCR_TAC_carry_rate=0.1,
                                       fix_recruit=NULL,fix_wcatch=NULL),
                                  only_data=TRUE)
  # 0.1まで繰越
  data_future_no_reserve <- list_modify(data_future_test$input,HCR_TAC_reserve_rate=0) %>%
      safe_call(make_future_data,.)

  res_future_noMSE <- test_sd0_future(data_future_test)$res1
  expect_equal(all(round(res_future_noMSE$HCR_realized[as.character(2019:2023),,"wcatch"]/
                         res_future_noMSE$HCR_realized[as.character(2019:2023),,"original_ABC_plus"],3)
                   ==0.9),TRUE)

  # 余るけど繰越をしない場合
  res_future_noreserve <- test_sd0_future(data_future_no_reserve)$res1  
  expect_equal(all(round(res_future_noreserve$HCR_realized[as.character(2019:2023),,"wcatch"]/
                         res_future_noreserve$HCR_realized[as.character(2019:2023),,"original_ABC_plus"],3)
                   ==1),TRUE)

  # 繰越しを量で決める場合
  expect_error(redo_future(data_future_test,list(HCR_TAC_reserve_amount=1000,
                                                 HCR_TAC_reserve_rate=0.1)))
  
  res_future <- redo_future(data_future_test,list(HCR_TAC_reserve_amount=3000,
                                                  HCR_TAC_carry_amount  =1000,
                                                  HCR_TAC_carry_rate    =NA,
                                                  HCR_TAC_reserve_rate  =NA))

  tmp <- mean(res_future$HCR_realized[as.character(2019:2027),,"original_ABC_plus"]-
              res_future$HCR_realized[as.character(2019:2027),,"wcatch"])
  expect_equal(mean(tmp),3000,tol=0.1)
  tmp <- mean(res_future$HCR_realized[as.character(2020:2027),,"reserved_catch"])
  expect_equal(mean(tmp),1000,tol=0.1)
  
  # MSEの場合
  res_future_MSE <- future_vpa(tmb_data=data_future_test$data,
                           optim_method="none",
                           multi_init = 1,SPRtarget=0.3,
                           do_MSE=TRUE, MSE_input_data=data_future_test,
                           MSE_nsim=1000)
  expect_equal(all(round(res_future_MSE$HCR_realized[as.character(2019:2023),,"wcatch"]/
                         res_future_MSE$HCR_realized[as.character(2019:2023),,"original_ABC_plus"],3)
                   ==0.9),TRUE)
#   check_MSE_sd0(data_future_test) # (通ることは確認。時間かかるので割愛)

  # 漁獲量一定方策＋繰越設定
  data_future_reserve_CC <- list_modify(data_future_test$input,
                                        fix_wcatch=tibble(year=2019:2025,wcatch=100)) %>%
      safe_call(make_future_data,.)


  res_future_reserve_CC <- future_vpa(tmb_data=data_future_reserve_CC$data,
                                      optim_method="none",
                                      multi_init = 1,SPRtarget=0.3,
                                      do_MSE=FALSE, MSE_input_data=data_future_test)
  round(res_future_reserve_CC$HCR_realized[as.character(2019:2025),1,"wcatch"]) %>%
      as.numeric() %>%  unlist %>%
      expect_equal(c(90,99,91,98,92,98,92)) # この数字は、TACを100、持ち越し率を0.1に固定したときのエクセルによる計算結果

  data_future_reserve_CC1 <- list_modify(data_future_reserve_CC$input,
                                        HCR_TAC_reserve_rate=0.3) %>%
      safe_call(make_future_data,.)
  res_future_reserve_CC1 <- future_vpa(tmb_data=data_future_reserve_CC1$data,
                                      optim_method="none",
                                      multi_init = 1,SPRtarget=0.3,
                                      do_MSE=FALSE, MSE_input_data=data_future_test)
  res_future_reserve_CC1$HCR_realized[as.character(2019:2025),1,"wcatch"] %>%
      round() %>% unlist() %>% as.numeric() %>% expect_equal(c(70,rep(77,6)))
  res_future_reserve_CC1$HCR_realized[as.character(2019:2025),1,"original_ABC"]%>%
      round() %>% unlist() %>% as.numeric() %>% expect_equal(c(100,rep(100,6)))
  res_future_reserve_CC1$HCR_realized[as.character(2019:2025),1,"original_ABC_plus"]%>%
      round() %>% unlist() %>% as.numeric() %>% expect_equal(c(100,rep(110,6)))

  expect_error(data_future_no_reserve <- list_modify(data_future_test$input,HCR_TAC_reserve_rate=-1) %>%
                   safe_call(make_future_data,.))

})

# Naoto Shinohara

# テストされていない関数たち

# future_vpa_R
# set_SR_mat
# SRF_HS
# SRF_BH
# SRF_RI
# make_array
# arrange_weight
# average_SR_mat
# sample_backward
# print.myarray
# naming_adreport
# trace_future
# get_summary_stat
# format_to_old_future
# safe_call
# HCR_default
# update_waa_mat
# get_wcatch

context("check set_SR_mat") # ----

test_that("set_SR_mat with sample data", {
  # サンプルデータ、パラメータとして以下を与える
  data(res_vpa)
  data(res_sr_HSL2)

  nsim = 10
  nyear = 50 # number of future year
  future_initial_year_name = 2017
  future_initial_year <- which(colnames(res_vpa$naa)==future_initial_year_name)
  total_nyear <- future_initial_year + nyear
  allyear_name <- min(as.numeric(colnames(res_vpa$naa))) + c(0:(total_nyear - 1))
  start_random_rec_year_name = 2018

  # 空のSR_matを作成
  SR_mat <- array(0, dim=c(total_nyear, nsim, 15),
                  dimnames=list(year=allyear_name, nsim=1:nsim,
                                par=c("a","b","rho", #1-3
                                      "SR_type", # 4
                                      "rand_resid", # 5
                                      "deviance", #6
                                      "recruit","ssb",
                                      "intercept","sd",#9-10
                                      "bias_factor", #11
                                      "blank2","blank3","blank4","blank5")))
  SR_mat[, , "deviance"]

  # set_SR_matを用いて、加入のdeviationを計算しSR_matに格納する。
  SR_mat <- set_SR_mat(res_vpa = res_vpa,
                       start_random_rec_year_name = start_random_rec_year_name,
                       SR_mat = SR_mat, res_SR = res_sr_HSL2, seed_number = 1,
                       resid_type = "lognormal", bias_correction = TRUE,
                       resample_year_range = 0, backward_duration = 0,
                       recruit_intercept = 0, recruit_age = 0,
                       model_average_option = NULL, regime_shift_option = NULL
  )
  SR_mat[, , "deviance"]

  # deviationに値が格納されているか（0以外の値になっているか）
  expect_equal(SR_mat[, , "deviance"][SR_mat[, , "deviance"] != 0] %>% length(),
               nrow(SR_mat[, , "deviance"]) * ncol(SR_mat[, , "deviance"]))
})


context("check arrange_weight") # check arrange_weight ----

test_that("check arrange_weight", {

  weight <- c(0.21, 0.79) ; sim <- 10
  Whether_duplicated <- arrange_weight(weight, sim) %>% unlist() %>% duplicated()
  # 出力リストの長さが足してnsimになるかどうか
  expect_equal(arrange_weight(weight, sim) %>%
                 purrr::map(function(x) length(x)) %>%
                 unlist() %>% sum(),
               sim)
  # リストの要素間で数値に重複がないかどうか
  expect_equal(c(1:length(Whether_duplicated))[Whether_duplicated],
               numeric(0))

  # 3つ以上の重み付けが与えられ、重み付けの和が1に満たない場合でのテスト。
  weight <- c(0.11, 0.22, 0.33) ; sim <- 10
  Whether_duplicated <- arrange_weight(weight, sim) %>% unlist() %>% duplicated()
  # 出力リストの長さが足してnsimになるかどうか
  expect_equal(arrange_weight(weight, sim) %>%
                 purrr::map(function(x) length(x)) %>%
                 unlist() %>% sum(),
               sim)
  # リストの要素間で数値に重複がないかどうか
  expect_equal(c(1:length(Whether_duplicated))[Whether_duplicated],
               numeric(0))

})


context("HCR_default") # ----

test_that("HCR_default",{
  HCR <- HCR_default(ssb=100000,Blimit=10000,Bban=1000,beta=0.8)
  expect_equal(HCR,0.8)
})

context("get_wcatch") # ----

test_that("get_wcatch",{
  expect_equal(get_wcatch(res_future_0.8HCR), apply(res_future_0.8HCR$wcaa,c(2,3),sum))
})

