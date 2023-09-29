# setup -------------------------------------------------------------------
library(agrometR)
library(tidyverse)
library(lubridate)
library(yyyymm)

# data mensual ------------------------------------------------------------
pers <- ym_seq(201001, format(Sys.time(), "%Y%m"))
pers <- rev(pers)

folder_data <- "dev/data-raw-dmc/"

fs::dir_create(folder_data)

# remove las 2
# try(
#   dir(folder_data, full.names = TRUE) |>
#     tail(2) |>
#     fs::file_delete()
# )
#
# try(
#   dir(folder_data, full.names = TRUE) |>
#     tail(2) |>
#     str_replace("raw", "daily") |>
#     fs::file_delete()
# )

walk(pers, function(per = 202308){

  figletr::figlet(per)

  fout <- fs::path(folder_data, per, ext = "rds")

  message(fout)

  if(fs::file_exists(fout)) return(TRUE)

  date_start <- (ym_to_date(per, day = 1) |> as_datetime()) + hours(4)
  date_end   <- (date_start + months(1) - seconds(1))

  # date_start <- format(date_start, "%Y-%m-%d %H:%M:%S")
  # date_end <- format(date_end, "%Y-%m-%d %H:%M:%S")

  dres <- agrometR::get_agro_data_dmc(
    agrometR::estaciones_dmc[["codigoNacional"]],
    # "330020",
    date_start = date_start,
    date_end = date_end,
    verbose = TRUE
  )

  # dres |>
  #   # filter(station_id ==  "330020") |>
  #   agrometR:::daily_aggregation_dmc() |>
  #   filter(as.Date(fecha_hora) == ymd(20230823)) |>
  #   # filter(station_id ==  "330020") |>
  #   glimpse()

  # agrometR::get_agro_data_from_api_dmc(950001, date_start = date_start, date_end = date_end)

  # corroboramos que todo esté dentro del periodo
  # stopifnot(nrow(dres) == nrow(filter(dres, format(momento, "%Y%m") == per)))

  # dres <- dres %>%
  #   filter(if_any(c(temp_promedio_aire:horas_frio), negate(is.na)))

  # dres |> summarise(min(fecha_hora), max(fecha_hora)) |> mutate(per = per, .before = 1)

  write_rds(dres, fout, compress = "xz")

})


# fs::dir_ls(folder_data) |>
#   walk(function(f = "dev/data-raw-dmc/201711.rds"){
#
#     message(f)
#
#     d <- readRDS(f)
#
#     d <- d |>
#       mutate(dplyr::across(tidyselect::everything(), ~ stringr::str_remove_all(.x, "°C$|kt$|°|%|Watt/m2$|hPas$|mm$"))) |>
#       mutate(dplyr::across(tidyselect:::where(is.character), stringr::str_trim)) |>
#       mutate(dplyr::across(tidyselect::everything(), readr::parse_guess))
#
#     if(has_name(d,"estacion_id")){
#
#       d <- d |>
#         rename(station_id = estacion_id)
#
#     }
#
#     write_rds(d, f, compress = "xz")
#
#   })

# parameters --------------------------------------------------------------
# URL_API <- "https://climatologia.meteochile.gob.cl/application/productos"
#
# pers <- ym_seq(200301, format(Sys.time(), "%Y%m"))
# pers <- rev(pers)
#
# folder_data <- "dev/data-raw-dmc/"
#
# # remove las 2
# try(
#   dir(folder_data, full.names = TRUE) |>
#     tail(2) |>
#     fs::file_delete()
# )
#
# fs::dir_create(folder_data)

# process -----------------------------------------------------------------
# estaciones
# estaciones <- httr::content(httr::GET(fs::path(URL_API, "estacionesRedEma")))
#
# destaciones <- estaciones$datosEstacion |>
#   map_df(as_tibble)
#
# destaciones
# destaciones |> filter(codigoNacional == 330020)
#
# url_get_content <- function(url){
#
#   httr::content(httr::GET(url))
#
# }
#
# safely_url_get_content <- purrr::safely(url_get_content)
#
# walk(pers, function(per = 202202){
#
#   figletr::figlet(per)
#
#   fout <- fs::path(folder_data, per, ext = "rds")
#
#   message(fout)
#
#   if(fs::file_exists(fout)) return(TRUE)
#
#   destacionesper <- map_df(destaciones$codigoNacional, function(estacion = 330020){
#
#     message("\t", estacion)
#
#     # "datosRecientesEma/180005/2018/06"
#     # "datosRecientesEma/330020/2018/06"
#     # per <- "201806"
#
#     yyyy <- str_sub(per, 0, 4)
#     mm   <- str_sub(per, 5, 6)
#
#     url_req <- str_glue("datosRecientesEma/{ estacion }/{ yyyy }/{ mm }")
#
#     message("\t", url_req)
#
#     url_req <- fs::path(URL_API, url_req)
#
#     r <- safely_url_get_content(url_req)
#
#     # str(r, max.level = 2)
#
#     if(is.null(r$result)) return(tibble())
#
#     r <- r$result
#
#     # jsonview::json_tree_view(r)
#     destacion <- map_df(r$datosEstaciones$datos, function(x){
#
#       x <- map(x, function(e){
#
#         if(is.null(e)) {
#           return(NA)
#         }
#         e
#       })
#
#       as_tibble(x)
#
#     })
#
#     destacion <- destacion |>
#       mutate(estacion_id = estacion, .before = 1)
#
#     destacion
#
#   })
#
#   # destacionesper |> count(estacion_id)
#
#   write_rds(destacionesper, fout, compress = "xz")
#
# })


# validar data histórica --------------------------------------------------
dhist <- dir(folder_data, full.names = TRUE) |>
  rev() |>
  map_df(function(f = "dev/data-raw-dga/202202.rds"){

    # fs::file_delete(f)
    message(f)

    dres <- readRDS(f)

    if(identical(dim(dres), c(0L, 0L))) return(dres)

    dres <- dres |>
      mutate(
        fecha = lubridate::ymd_hms(momento),
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
  filter(anio >= 2006) |>
  add_row(anio = 2011, mes = "01") |>
  add_row(anio = 2007, mes = "01") |>
  complete(station_id, anio, mes) |>
  crossing() |>
  filter(!is.na(station_id)) |>
  mutate(
    periodo = yyyymm::ym_to_date(str_c(anio, mes)),
    ind = ifelse(is.na(n), FALSE, TRUE),
  ) |>
  filter(periodo < lubridate::ymd(20220601)) |>
  ggplot() +
  geom_tile(aes(periodo, factor(station_id), fill = n)) +
  scale_fill_continuous(na.value = "gray90") +
  scale_x_date(
    date_breaks = "1 year",
    # limits = c(lubridate::ymd(20060101), lubridate::ymd(20220601))
  ) +
  theme_minimal()

p

saveRDS(p, "dev/plot_hist_dmc.rds")

beepr::beep(4)

