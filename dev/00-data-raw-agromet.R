# setup -------------------------------------------------------------------
library(tidyverse)
library(agrometR)
library(lubridate)
library(yyyymm)

# data --------------------------------------------------------------------
pers <- ym_seq(200001, format(Sys.time(), "%Y%m"))
pers <- rev(pers)

folder_data <- "dev/data-raw-agromet/"

fs::dir_create(folder_data)

# remove las 2
# try(
#   dir("data/rds", full.names = TRUE) |>
#     tail(2) |>
#     fs::file_delete()
#   )

walk(pers, function(per = 202202){

  figletr::figlet(per)

  fout <- fs::path(folder_data, per, ext = "rds")

  message(fout)

  if(fs::file_exists(fout)) return(TRUE)

  date_start <- ym_to_date(per, day = 1) |> as_datetime()
  date_end   <- date_start + months(1) - seconds(1)

  # date_start <- format(date_start, "%Y-%m-%d %H:%M:%S")
  # date_end <- format(date_end, "%Y-%m-%d %H:%M:%S")

  dres <- agrometR::get_agro_data(
    estaciones_agromet[["ema"]],
    date_start = date_start,
    date_end = date_end,
    verbose = TRUE
  )

  # corroboramos que todo esté dentro del periodo
  stopifnot(nrow(dres) == nrow(filter(dres, format(fecha_hora, "%Y%m") == per)))

  dres <- dres %>%
    filter(if_any(c(temp_promedio_aire:horas_frio), negate(is.na)))

  # dres |> summarise(min(fecha_hora), max(fecha_hora)) |> mutate(per = per, .before = 1)

  write_rds(dres, fout, compress = "xz")

})


# validar periodos --------------------------------------------------------



