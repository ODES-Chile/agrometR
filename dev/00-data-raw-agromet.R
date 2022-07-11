# setup -------------------------------------------------------------------
library(tidyverse)
library(agrometR)
library(lubridate)
library(yyyymm)

# data --------------------------------------------------------------------
pers <- ym_seq(200301, format(Sys.time(), "%Y%m"))
pers <- rev(pers)

folder_data <- "dev/data-raw-agromet/"

fs::dir_create(folder_data)

# remove las 3
try(
  dir(folder_data, full.names = TRUE) |>
    tail(3) |>
    fs::file_delete()
  )

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

# validar data histórica --------------------------------------------------
dhist <- dir(folder_data, full.names = TRUE) |>
  rev() |>
  map_df(function(f = "dev/data-raw-agromet/202202.rds"){

    # fs::file_delete(f)
    message(f)

    dres <- readRDS(f)

    if(identical(dim(dres), c(0L, 0L))) return(dres)

    dres <- dres |>
      mutate(
        fecha = lubridate::ymd_hms(fecha_hora),
        anio = lubridate::year(fecha),
        mes = format(fecha, "%m"),
        .before = 1
      )

    # dres |> filter(str_c(anio, mes) != str_remove(basename(f), ".rds"))

    dres <- dres |>
      count(station_id, anio, mes)

    nfuera <- dres |>
      filter(str_c(anio, mes) != str_remove(basename(f), ".rds")) |>
      nrow()

    stopifnot(nfuera == 0)

    dres

  })

p <- dhist |>
  # filter(anio >= 2006) |>
  # bind_rows()
  # add_row(anio = 2011, mes = "01") |>
  # add_row(anio = 2007, mes = "01") |>
  complete(station_id, anio, mes) |>
  crossing() |>
  filter(!is.na(station_id)) |>
  mutate(
    periodo = yyyymm::ym_to_date(str_c(anio, mes)),
    ind = ifelse(is.na(n), FALSE, TRUE),
  ) |>
  # filter(periodo < lubridate::ymd(20220601)) |>
  ggplot() +
  geom_tile(aes(periodo, factor(station_id), fill = n)) +
  scale_fill_continuous(na.value = "gray90") +
  scale_x_date(
    date_breaks = "1 year",
    limits = c(lubridate::ymd(20060101), lubridate::ymd(20220601))
  ) +
  theme_minimal()

p

saveRDS(p, "dev/plot_hist_agromet.rds")



# resumen diario ----------------------------------------------------------
dfdiario <- dir(folder_data, full.names = TRUE) |>
  rev() |>
  map_df(function(f = "dev/data-raw-agromet/202112.rds"){

    # fs::file_delete(f)
    message(f)

    d <- readRDS(f)

    # glimpse(d)

    if(identical(dim(d), c(0L, 0L))) return(d)

    if(nrow(d) == 0) return(tibble())

    # removemos unidades
    # trimeamos
    # parsemos
    d <- d |>
      mutate(across(everything(), ~ str_remove_all(.x, "°C$|kt$|°|%|Watt/m2$|hPas$|mm$"))) |>
      mutate(across(where(is.character), str_trim)) |>
      mutate(across(everything(), readr::parse_guess))

    # glimpse(d)

    dres <- d |>
      mutate(fecha_hora = lubridate::ceiling_date(fecha_hora, "hour"), .before = 1) |>
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

    # glimpse(dres)

    dres

  })


glimpse(dfdiario)

dfdiario <- dfdiario |>
  rename(estacion_id = station_id) |>
  arrange(fecha_hora, estacion_id) |>
  mutate(fuente =  "agromet", .before = 1)

glimpse(dfdiario)

saveRDS(dfdiario, "dev/data/agromet_diaria.rds")

