# setup -------------------------------------------------------------------
library(tidyverse)
library(agrometR)
library(lubridate)
library(yyyymm)

folder_data <- "dev/data-raw-dmc/"
try(dir.create("dev/data-daily-dmc"))

# resumen diario ----------------------------------------------------------
dir(folder_data, full.names = TRUE) |>
  rev() |>
  walk(function(f = "dev/data-raw-dmc/202308.rds"){

    # f = "dev/data-raw-dmc/202107.rds"
    # fs::file_delete(f)
    # message(f)
    cli::cli_progress_step(f)

    fout <- stringr::str_replace(f, "data-raw-dmc", "data-daily-dmc")

    if(file.exists(fout)) return(TRUE)

    d <- readRDS(f)

    if(identical(dim(d), c(0L, 0L))) return(TRUE)

    if(nrow(d) == 0) return(TRUE)

    # glimpse(d)
    #
    # removemos unidades
    # trimeamos
    # parsemos
    d <- d |>
      # mutate(across(everything(), ~ str_remove_all(.x, "°C$|kt$|°|%|Watt/m2$|hPas$|mm$"))) |>
      # mutate(across(where(is.character), str_trim)) |>
      # mutate(across(everything(), readr::parse_guess)) |>
      filter(TRUE)

    ddiario <- agrometR:::daily_aggregation_dmc(d)

    # ddiario |>
    #   # agrometR:::daily_aggregation_dmc() |>
    #   filter(as.Date(fecha_hora) == ymd(20230823)) |>
    #   filter(station_id ==  "330020") |>
    #   glimpse()

    ddiario <- ddiario |>
      filter(format(fecha_hora, "%Y%m") == str_extract(fout, "[0-9]{6}"))

    ddiario |>
      count(year(fecha_hora), month(fecha_hora))

    ddiario

    saveRDS(ddiario, fout)

  })

beepr::beep(4)
