#' Get data from https://climatologia.meteochile.gob.cl API
#'
#' @param stations_id A numeric value indicating stations ID from `agrometR::estaciones_dmc`.
#' @param date_start A value parseable by `lubridate::as_datetime`, for example `"2020-11-30 01:00:00"`.
#' @param date_end Same as `date_start` parameter.
#' @param verbose A logical value to show or not a progress bar with eta.
#'
#' @examples
#'
#' get_agro_data_dmc(180042 , "2020-11-30 01:00:00", "2020-12-15 01:00:00")
#'
#' get_agro_data_dmc(c(230004, 220002), "2020-11-30 01:00:00", "2020-12-15 01:00:00", verbose = TRUE)
#'
#' @export
get_agro_data_dmc <- function(stations_id = NULL, date_start = NULL, date_end = NULL, verbose = FALSE){

  # stations_id <- sample(agrometR::estaciones_dmc[["codigoNacional"]], size = 20)
  # verbose <- TRUE
  # date_start <- "2020-11-30"
  # date_end   <- "2020-12-15 01:00:00"

  # validation stations_id
  stations_id <- sort(unique(stations_id))

  if(!all(stations_id %in% agrometR::estaciones_dmc[["codigoNacional"]])){

    warning("Some stations_id does not exist. Considering existing stations")
    stations_id <- intersect(stations_id, agrometR::estaciones_dmc[["codigoNacional"]])

  }

  # validation dates
  date_limits <- list(date_start, date_end) |>
    purrr::map(lubridate::as_datetime) |>
    purrr::map_chr(format, "%Y-%m-%d+%H:%M:%S") |>
    # purrr::map_chr(format, "%Y-%m-%d%2b%H:%M:%S") |>
    sort()

  fun_dnwlod <- get_agro_data_from_api_dmc

  if(verbose) {

    pb <- progress::progress_bar$new(
      total = length(stations_id),
      format = " Downloading data from station :station [:bar] :percent eta: :eta"
      )

    fun_dnwlod <- function(station_id,  date_start, date_end){
      pb$tick(tokens = list(station = station_id))
      get_agro_data_from_api_dmc(station_id,  date_start, date_end)
    }

  }

  dout <- purrr::map_df(stations_id, fun_dnwlod, date_start = date_start, date_end = date_end)

  dout

}

url_get_content <- function(url){

  httr::content(httr::GET(url))

}

safely_url_get_content <- purrr::safely(url_get_content)

#' @rdname get_agro_data_dmc
#'
#' @param station_id A numeric length 1 value indicating station ID from `estaciones_agromet`.
#'
#' @examples
#'
#' get_agro_data_from_api_dmc(380013, "2020-11-30 01:00:00", "2020-12-15 01:00:00")
#'
#' @export
get_agro_data_from_api_dmc <- function(station_id = NULL, date_start = NULL, date_end = NULL){

  # station_id <- 950001
  # date_start <- "2020-11-30 01:00:00"
  # date_start <- "2020-11-30"
  # date_end   <- "2020-12-15 01:00:00"
  # date_end   <- "2022-04-20 22:15:41 -04"

  stopifnot(
    !is.null(station_id),
    station_id %in% agrometR::estaciones_dmc[["codigoNacional"]],
    length(station_id) == 1
    )

  datetime_limits <- list(date_start, date_end) |>
    purrr::map(lubridate::as_datetime) |>
    # purrr::map_chr(format, "%Y-%m-%d+%H:%M:%S") |>
    # purrr::map_chr(format, "%Y-%m-%d%2b%H:%M:%S") |>
    unlist() |>
    sort() |>
    lubridate::as_datetime()

  datetime_limits

  # estrategia es obtener más data, los periodos y luego filtrar.
  date_limits_pers <- lubridate::floor_date(datetime_limits, "month") |>
    lubridate::as_date()

  periodos <- seq.Date(date_limits_pers[1], date_limits_pers[2], by = "month")
  periodos <- format(periodos, "%Y%m")

  destacion <- map_df(periodos, function(per = periodos[1]){

    # message(per)

    # "datosRecientesEma/180005/2018/06"
    # "datosRecientesEma/330020/2018/06"
    # per <- "201806"

    yyyy <- stringr::str_sub(per, 0, 4)
    mm   <- stringr::str_sub(per, 5, 6)


    URL_API <- "https://climatologia.meteochile.gob.cl/application/productos"
    url_req <- stringr::str_glue("datosRecientesEma/{ station_id }/{ yyyy }/{ mm }")

    url_req <- file.path(URL_API, url_req)
    # message("\t", url_req)

    r <- safely_url_get_content(url_req)
    # r <-  httr::content(httr::GET(url_req))

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

      tibble::as_tibble(x)

    })

    destacion <- destacion |>
      dplyr::mutate(station_id = station_id, .before = 1)

    destacion

  })

  if(nrow(destacion) == 0) return(destacion)

  whr <- utils::getFromNamespace("where", "tidyselect")

  # some parsing due API return values as "10 °C" for example
  destacion <- destacion |>
    mutate(dplyr::across(tidyselect::everything(), ~ stringr::str_remove_all(.x, "°C$|kt$|°|%|Watt/m2$|hPas$|mm$"))) |>
    mutate(dplyr::across(whr(is.character), stringr::str_trim)) |>
    mutate(dplyr::across(tidyselect::everything(), readr::parse_guess))

  # filter by specific dates limits
  destacion <- destacion |>
    dplyr::arrange(.data$momento) |>
    dplyr::filter(datetime_limits[1] <= .data$momento) |>
    dplyr::filter(.data$momento <= datetime_limits[2])

  destacion

}
