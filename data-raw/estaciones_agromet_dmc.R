library(tidyverse)


# agromet -----------------------------------------------------------------
estaciones_agromet <- readxl::read_excel("data-raw/Emas_18-04-2022.xlsx")

glimpse(estaciones_agromet)

estaciones_agromet <- janitor::clean_names(estaciones_agromet)

estaciones_agromet

glimpse(estaciones_agromet)

usethis::use_data(estaciones_agromet, overwrite = TRUE)

stringr::str_glue(
  "\t\\item \\code{{ {el} }} : {el}.",
  el = names(agrometR::estaciones_agromet)
  )


# dmc ---------------------------------------------------------------------
URL_API <- "https://climatologia.meteochile.gob.cl/application/productos"

estaciones_dmc <- httr::content(httr::GET(fs::path(URL_API, "estacionesRedEma")))

estaciones_dmc <- estaciones_dmc$datosEstacion |>
  map_df(as_tibble)

estaciones_dmc <- estaciones_dmc |>
  mutate(across(c(latitud, longitud), as.numeric))

glimpse(estaciones_dmc)

estaciones_dmc |> nrow()
estaciones_dmc |> distinct(codigoNacional, codigoOMM, codigoOACI) |> nrow()
estaciones_dmc |> distinct(codigoNacional, codigoOMM,) |> nrow()
estaciones_dmc |> distinct(codigoNacional) |> nrow()

usethis::use_data(estaciones_dmc, overwrite = TRUE)

stringr::str_glue(
  "\t\\item \\code{{ {el} }} : {el}.",
  el = names(agrometR::estaciones_dmc)
)



