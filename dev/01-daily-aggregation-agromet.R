# setup -------------------------------------------------------------------
library(tidyverse)
library(agrometR)
library(lubridate)
library(yyyymm)

folder_data <- "dev/data-raw-agromet/"

# resumen diario ----------------------------------------------------------
dir(folder_data, full.names = TRUE) |>
  rev() |>
  walk(function(f = "dev/data-raw-agromet/202112.rds"){

    # fs::file_delete(f)
    message(f)

    fout <- stringr::str_replace(f, "data-raw-agromet", "data-daily-agromet")

    if(file.exists(fout)) return(TRUE)

    d <- readRDS(f)

    if(identical(dim(d), c(0L, 0L))) return(TRUE)

    if(nrow(d) == 0) return(TRUE)

    # removemos unidades
    # trimeamos
    # parsemos
    d <- d |>
      mutate(across(everything(), ~ str_remove_all(.x, "°C$|kt$|°|%|Watt/m2$|hPas$|mm$"))) |>
      mutate(across(where(is.character), str_trim)) |>
      mutate(across(everything(), readr::parse_guess))

    # glimpse(d)

    ddiario <- d |>
      mutate(fecha_hora = lubridate::ceiling_date(fecha_hora, "day"), .before = 1) |>
      group_by(station_id, fecha_hora) |>
      summarise(
        .groups = "drop",
        temp_promedio_aire    = mean(temp_promedio_aire, na.rm = TRUE),
        precipitacion_horaria = sum(precipitacion_horaria, na.rm = TRUE),
        humed_rel_promedio    = mean(humed_rel_promedio, na.rm = TRUE),
        presion_atmosferica   = mean(presion_atmosferica, na.rm = TRUE),
        radiacion_solar_max   = mean(radiacion_solar_max, na.rm = TRUE),
        veloc_max_viento      = NA, # REVISAR
        temp_minima           = min(temp_minima, na.rm = TRUE),
        temp_maxima           = max(temp_maxima, na.rm = TRUE),
        direccion_del_viento  = mean(direccion_del_viento, na.rm = TRUE), # REVISAR
        grados_dia            = NA,
        horas_frio            = NA
      ) |>
      ungroup()

    # glimpse(ddiario)

    ddiario

    saveRDS(ddiario, fout)

  })



