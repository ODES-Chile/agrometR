library(tidyverse)

estaciones_agromet <- readxl::read_excel("data-raw/Emas_18-04-2022.xlsx")

glimpse(estaciones_agromet)

estaciones_agromet <- janitor::clean_names(estaciones_agromet)

usethis::use_data(estaciones_agromet, overwrite = TRUE)

stringr::str_glue(
  "\t\\item \\code{{ {el} }} : {el}.",
  el = names(agrometR::estaciones_agromet)
  )

