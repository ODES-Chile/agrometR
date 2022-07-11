#' Get data from agromet.cl API
#'
#' @param stations_id A numeric value indicating stations ID from `agrometR::estaciones_agromet`.
#' @param date_start A value parseable by `lubridate::as_datetime`, for example `"2020-11-30 01:00:00"`.
#' @param date_end Same as `date_start` parameter.
#' @param verbose A logical value to show or not a progress bar with eta.
#'
#' @examples
#'
#' get_agro_data(1:10, "2020-11-30 01:00:00", "2020-12-15 01:00:00")
#'
#' get_agro_data(1:10, "2020-11-30 01:00:00", "2020-12-15 01:00:00", verbose = TRUE)
#'
#' @importFrom rlang .data
#' @importFrom lubridate as_datetime
#' @importFrom purrr map map_df map_chr reduce
#' @importFrom dplyr mutate
#' @import progress
#'
#' @export
get_agro_data <- function(stations_id = NULL, date_start = NULL, date_end = NULL, verbose = FALSE){

  # stations_id <- sample(estaciones_agromet[["ema"]], size = 20)
  # stations_id <- c(1:10, 10, 10, -99)
  # verbose <- TRUE
  # date_start <- "2020-11-30"
  # date_end   <- "2020-12-15 01:00:00"

  # validation stations_id
  stations_id <- sort(unique(stations_id))

  if(!all(stations_id %in% agrometR::estaciones_agromet[["ema"]])){

    warning("Some stations_id does not exist. Considering existing stations")
    stations_id <- intersect(stations_id, agrometR::estaciones_agromet[["ema"]])

  }

  # validation dates
  date_limits <- list(date_start, date_end) |>
    purrr::map(lubridate::as_datetime) |>
    purrr::map_chr(format, "%Y-%m-%d+%H:%M:%S") |>
    # purrr::map_chr(format, "%Y-%m-%d%2b%H:%M:%S") |>
    sort()

  fun_dnwlod <- get_agro_data_from_api

  if(verbose) {

    pb <- progress::progress_bar$new(
      total = length(stations_id),
      format = " Downloading data from station :station [:bar] :percent eta: :eta"
      )

    fun_dnwlod <- function(station_id,  date_start, date_end){
      pb$tick(tokens = list(station = station_id))
      get_agro_data_from_api(station_id,  date_start, date_end)
    }

  }

  dout <- purrr::map_df(stations_id,  fun_dnwlod,  date_start = date_start,  date_end = date_end)

  dout

}

#' @rdname get_agro_data
#'
#' @param station_id A numeric length 1 value indicating station ID from `estaciones_agromet`.
#'
#' @examples
#'
#' get_agro_data_from_api(108, "2020-11-30 01:00:00", "2020-12-15 01:00:00")
#'
#' @importFrom httr GET content
#' @importFrom xml2 read_xml xml_find_all
#' @importFrom janitor make_clean_names
#' @importFrom stringr str_remove_all str_split
#' @importFrom readr type_convert
#' @importFrom tibble tibble
#' @export
get_agro_data_from_api <- function(station_id = NULL, date_start = NULL, date_end = NULL){

  # station_id <- 109
  # date_start <- "2020-11-30 01:00:00"
  # date_start <- "2020-11-30"
  # date_end   <- "2020-12-15 01:00:00"
  # date_end   <- "2022-04-20 22:15:41 -04"

  stopifnot(
    !is.null(station_id),
    station_id %in% agrometR::estaciones_agromet[["ema"]],
    length(station_id) == 1
    )

  date_limits <- list(date_start, date_end) |>
    purrr::map(lubridate::as_datetime) |>
    purrr::map_chr(format, "%Y-%m-%d+%H:%M:%S") |>
    # purrr::map_chr(format, "%Y-%m-%d%2b%H:%M:%S") |>
    sort()

  # r <- httr::GET(
  #   url = 'https://www.agromet.cl',
  #   path = '/ext/aux/getGraphData.php',
  #   query = list(
  #     ema_ia_id = station_id,
  #     dateFrom  = date_limits[1],
  #     dateTo    = date_limits[2],
  #     portada = "false"
  #   ),
  #   config = httr::config(ssl_verifypeer = FALSE)
  # )

  url_api <- "https://www.agromet.cl/ext/aux/getGraphData.php"

  url_req <- stringr::str_glue("{ url_api }?ema_ia_id={ station_id }&dateFrom={ date_limits[1] }&dateTo={ date_limits[2] }&portada=false")

  r <- httr::GET(
    url = url_req,
    config = httr::config(ssl_verifypeer = FALSE)
  )

  units <- r |>
    httr::content("text") |>
    xml2::read_xml() |>
    xml2::xml_find_all("eje") |>
    xml2::xml_text() |>
    stringr::str_remove_all("^[0-9]{1,2}\\||\\|[0-9]{1,2}$|\\(.*\\)")

  desc_cols <- r |>
    httr::content("text") |>
    xml2::read_xml() |>
    xml2::xml_find_all("gra") |>
    xml2::xml_text() |>
    stringr::str_remove_all("^[0-9]{1,2}\\||\\|[0-9]{1,2}$")

  col_names <- desc_cols |>
    stringr::str_remove_all("\\(.*\\)") |>
    janitor::make_clean_names()

  units     <- c("hora", units)
  desc_cols <- c("Fecha", desc_cols)
  col_names <- c("fecha_hora", col_names)

  idx <- c(seq(1:12)*2)

  d <- r |>
    httr::content("text") |>
    xml2::read_xml() |>
    xml2::xml_find_all("dato") |>
    xml2::xml_text() |>
    stringr::str_split("\\|") |>
    purrr::map(t) |>
    purrr::reduce(rbind) |>
    as.data.frame() |>
    tibble::as_tibble() |>
    readr::type_convert(col_types = readr::cols()) |>
    dplyr::select(idx) |>
    purrr::set_names(col_names)

  d <- d |>
    dplyr::mutate(station_id = station_id, .before = 1)

  # dplyr::glimpse(d)

  dextra <- tibble::tibble(columna = col_names, unit = units, description = desc_cols)

  attr(d, "info") <- dextra

  d

}
