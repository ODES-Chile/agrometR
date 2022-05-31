# setup -------------------------------------------------------------------
library(tidyverse)
library(yyyymm)# remotes::install_github("jbkunst/yyyymm")
# parameters --------------------------------------------------------------
URL_API <- "https://climatologia.meteochile.gob.cl/application/productos"

pers <- ym_seq(200301, format(Sys.time(), "%Y%m"))
pers <- rev(pers)

folder_data <- "dev/data-raw-dmc/"

fs::dir_create(folder_data)

# process -----------------------------------------------------------------

# estaciones
estaciones <- httr::content(httr::GET(fs::path(URL_API, "estacionesRedEma")))

destaciones <- estaciones$datosEstacion |>
  map_df(as_tibble)

destaciones
destaciones |> filter(codigoNacional == 330020)

url_get_content <- function(url){

  httr::content(httr::GET(url))

}

safely_url_get_content <- purrr::safely(url_get_content)

walk(pers, function(per = 202202){

  figletr::figlet(per)

  fout <- fs::path(folder_data, per, ext = "rds")

  message(fout)

  if(fs::file_exists(fout)) return(TRUE)

  destacionesper <- map_df(destaciones$codigoNacional, function(estacion = 330020){

    message("\t", estacion)

    # "datosRecientesEma/180005/2018/06"
    # "datosRecientesEma/330020/2018/06"
    # per <- "201806"

    yyyy <- str_sub(per, 0, 4)
    mm   <- str_sub(per, 5, 6)

    url_req <- str_glue("datosRecientesEma/{ estacion }/{ yyyy }/{ mm }")

    message("\t", url_req)

    url_req <- fs::path(URL_API, url_req)

    r <- safely_url_get_content(url_req)

    # str(r, max.level = 2)

    if(is.null(r$result)) return(tibble())

    r <- r$result

    # jsonview::json_tree_view(r)
    destacion <- map_df(r$datosEstaciones$datos, function(x){

      x <- map(x, function(e){

        if(is.null(e)) {
          return(NA)
        }
        e
      })

      as_tibble(x)

    })

    destacion <- destacion |>
      mutate(estacion_id = estacion, .before = 1)

    destacion

  })

  # destacionesper |> count(estacion_id)

  write_rds(destacionesper, fout, compress = "xz")

})


# validar data ------------------------------------------------------------
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
      count(estacion_id, anio, mes)

    nfuera <- dres |>
      filter(str_c(anio, mes) != str_remove(basename(f), ".rds")) |>
      nrow()

    stopifnot(nfuera == 0)

    dres

  })

dhist |>
  filter(anio >= 2006) |>
  add_row(anio = 2011, mes = "01") |>
  add_row(anio = 2007, mes = "01") |>
  complete(estacion_id, anio, mes) |>
  crossing() |>
  filter(!is.na(estacion_id)) |>
  mutate(
    periodo = yyyymm::ym_to_date(str_c(anio, mes)),
    ind = ifelse(is.na(n), FALSE, TRUE),
    ) |>
  filter(periodo < lubridate::ymd(20220601)) |>
  ggplot() +
  geom_tile(aes(periodo, factor(estacion_id), fill = n)) +
  scale_fill_continuous(na.value = "gray90") +
  scale_x_date(
    date_breaks = "1 year",
    limits = c(lubridate::ymd(20060101), lubridate::ymd(20220601))
    ) +
  theme_minimal()



# resumen diario ----------------------------------------------------------
dresumen <- dir(folder_data, full.names = TRUE) |>
  rev() |>
  map_df(function(f = "dev/data-raw-dmc/202202.rds"){

    # fs::file_delete(f)
    message(f)

    d <- readRDS(f)

    glimpse(d)

    if(identical(dim(dres), c(0L, 0L))) return(d)

    # removemos unidades
    # trimeamos
    # parsemos
    d <- d |>
      mutate(across(everything(), ~ str_remove_all(.x, "°C$|kt$|°|%|Watt/m2$|hPas$|mm$"))) |>
      mutate(across(where(is.character), str_trim)) |>
      mutate(across(everything(), readr::parse_guess))

    # redondeamos por día y resumimos a lo agromet
    dejemplo <- readRDS("dev/data-raw-agromet/202205.rds")

    glimpse(dejemplo)
    glimpse(d)

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


    d |>
      mutate(fecha_hora = lubridate::ceiling_date(momento, "hour"), .before = 1) |>
      group_by(fecha_hora) |>
      summarise(
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
      glimpse()



    dres <- dres |>
      mutate(
        fecha = lubridate::ymd_hms(momento),
        anio = lubridate::year(fecha),
        mes = format(fecha, "%m"),
        .before = 1
      )

    # dres |> filter(str_c(anio, mes) != str_remove(basename(f), ".rds"))

    dres <- dres |>
      count(estacion_id, anio, mes)

    nfuera <- dres |>
      filter(str_c(anio, mes) != str_remove(basename(f), ".rds")) |>
      nrow()

    stopifnot(nfuera == 0)

    dres

  })



