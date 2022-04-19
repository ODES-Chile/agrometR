#' @export
get_agro_data <- function(stations_id = NULL){


  TRUE
  agrometR::estaciones
  # ids <- get_stations(where)$identificador
  # resChk <- check_variables(ids,variables)
  # idVars <- resChk[[1]]
  # idSts <- resChk[[2]]
  #
  # #type='estaciones',idEsta,idVar,time_span,key=key
  # nameSta <- dataEst$nombre[dataEst$identificador %in% idSts]
  # nameVars <- infoEsta$shorthName[infoEsta$identificador %in% idVars]
  #
  # message('\n Downloading data...')
  # pb <- txtProgressBar(min = 0, max = length(idSts)*length(idVars), style = 3)
  # c<- 0
  # res <- lapply(seq_along(idSts),function(j){
  #   c <<- c+1
  #   print(paste0('j:',j))
  #   setTxtProgressBar(pb, c)
  #   res2 <- lapply(seq_along(idVars), function(i){
  #     c <<- c+1
  #     print(paste0('i:',i))
  #     setTxtProgressBar(pb, c)
  #     dataSt <- .getFromAPI(type = 'muestras',
  #                           idEsta = idSts[j],
  #                           idVar = idVars[i],
  #                           time_span = time_span,
  #                           key = key)
  #     print(dataSt)
  #     if (length(dataSt) == 0) {
  #       return()
  #     } else {
  #       dataSt$var <- nameVars[i]
  #       dataSt$cod <- idSts[j]
  #       return(dataSt)
  #     }
  #   })
  #
  #   if (length(res2) != 0){
  #     dataVars <- Reduce(rbind,res2)
  #     dataVars$station <- nameSta[j]
  #     return(dataVars)
  #   } else return()
  #
  #   # if (length(nameVars) > 1 & !is.null(dataVars)) {
  #   #   dataVars <- dataVars[,-seq(3,dim(dataVars)[2],2)]
  #   # }
  #
  #
  # })
  #
  # out <- Reduce(rbind, res)
  # out$valor <- as.numeric(out$valor)
  # return(tibble(out))
}



#' Get data from agromet.cl API
#'
#' @examples
#'
#' get_agro_data_from_api(108, "2020-11-30 01:00:00", "2020-12-15 01:00:00")
#'
#' @export
get_agro_data_from_api <- function(station_id = NULL, date_start = NULL, date_end = NULL){


  # station_id <- 109
  # date_start <- "2020-11-30 01:00:00"
  # date_end   <- "2020-12-15 01:00:00"
  # fmt <- "%Y-%m-%d+%H:%M:%S"

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

  # dplyr::glimpse(d)

  dextra <- tibble::tibble(columna = col_names, unit = units, description = desc_cols)

  attr(d, "info") <- dextra

  d

}
