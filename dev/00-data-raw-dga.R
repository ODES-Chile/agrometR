# setup -------------------------------------------------------------------
library(tidyverse)
library(yyyymm)

# parameters --------------------------------------------------------------
URL_API <- "https://climatologia.meteochile.gob.cl/application/productos"

pers <- ym_seq(200001, format(Sys.time(), "%Y%m"))
pers <- rev(pers)

folder_data <- "dev/data-raw-dga/"

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
