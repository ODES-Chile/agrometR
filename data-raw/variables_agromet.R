d <- agrometR::get_agro_data_from_api(
  109,
  Sys.Date() - (300 - 10)*24*60*60/100000,
  Sys.Date() - (300 -  0)*24*60*60/100000
  )

dplyr::glimpse(tail(d))

variables_agromet <- attr(d, "info")

variables_agromet

dplyr::glimpse(variables_agromet)

usethis::use_data(variables_agromet, overwrite = TRUE)
