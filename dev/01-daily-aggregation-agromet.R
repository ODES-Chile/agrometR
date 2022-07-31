# setup -------------------------------------------------------------------
library(tidyverse)
library(agrometR)
library(lubridate)
library(yyyymm)

folder_data <- "dev/data-raw-agromet/"
try(dir.create("dev/data-daily-agromet"))

# resumen diario ----------------------------------------------------------
dir(folder_data, full.names = TRUE) |>
  rev() |>
  walk(function(f = "dev/data-raw-agromet/202112.rds"){

    # f = "dev/data-raw-agromet/202112.rds"
    # fs::file_delete(f)
    message(f)

    fout <- stringr::str_replace(f, "data-raw-agromet", "data-daily-agromet")

    if(file.exists(fout)) return(TRUE)

    d <- readRDS(f)

    if(identical(dim(d), c(0L, 0L))) return(TRUE)

    if(nrow(d) == 0) return(TRUE)

    glimpse(d)

    # removemos unidades
    # trimeamos
    # parsemos
    d <- d |>
      mutate(across(everything(), ~ str_remove_all(.x, "°C$|kt$|°|%|Watt/m2$|hPas$|mm$"))) |>
      mutate(across(where(is.character), str_trim)) |>
      mutate(across(everything(), readr::parse_guess))

    ddiario <- agrometR:::daily_aggregation_ran(d)

    ddiario <- ddiario |>
      filter(format(fecha_hora, "%Y%m") == str_extract(fout, "[0-9]{6}"))

    ddiario |>
      count(year(fecha_hora), month(fecha_hora))

    glimpse(ddiario)

    ddiario

    saveRDS(ddiario, fout)

  })

beepr::beep(4)


