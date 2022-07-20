# setup -------------------------------------------------------------------
library(tidyverse)
library(agrometR)
library(lubridate)
library(yyyymm)

folder_data <- "dev/data-raw-dmc/"

# resumen diario ----------------------------------------------------------
dir(folder_data, full.names = TRUE) |>
  rev() |>
  walk(function(f = "dev/data-raw-dmc/202107.rds"){

    # fs::file_delete(f)
    message(f)

    fout <- stringr::str_replace(f, "data-raw-dmc", "data-daily-dmc")

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

    # redondeamos por día y resumimos a lo agromet
    # dejemplo <- readRDS("dev/data-raw-agromet/202205.rds")

    # glimpse(dejemplo)
    # glimpse(d)

    # d |>
    #   filter(!is.na(aguaCaidaDelMinuto))
    #
    # d |>
    #   filter(estacion_id  == 180005) |>
    #   filter(momento > lubridate::ymd_hms("2022/02/14 06:00:00")) |>
    #   filter(momento < lubridate::ymd_hms("2022/02/15 12:00:00")) |>
    #   select(momento, contains("agua")) |>
    #   gather(k, v, -momento) |>
    #   ggplot(aes(momento, v, group = k)) +
    #   geom_line() +
    #   facet_grid(vars(k))

    ddiario <- d |>
      mutate(fecha_hora = lubridate::ceiling_date(momento, "day"), .before = 1) |>
      group_by(station_id, fecha_hora) |>
      summarise(
        .groups = "drop",
        temp_promedio_aire    = mean(temperatura, na.rm = TRUE),
        precipitacion_horaria = sum(aguaCaidaDelMinuto, na.rm = TRUE), # REVISAR!!!!!!
        humed_rel_promedio    = mean(humedadRelativa, na.rm = TRUE),
        presion_atmosferica   = mean(presionEstacion, na.rm = TRUE), # REVISAR
        radiacion_solar_max   = mean(radiacionGlobalInst, na.rm = TRUE), # REVISAR
        veloc_max_viento      = NA, # REVISAR
        temp_minima           = min(temperatura, na.rm = TRUE), # REVISAR
        temp_maxima           = max(temperatura, na.rm = TRUE), # REVISAR
        direccion_del_viento  = mean(direccionDelViento), # REVISAR
        grados_dia            = NA,
        horas_frio            = NA
      ) |>
      ungroup()

    # glimpse(ddiario)

    ddiario

    saveRDS(ddiario, fout)

  })
