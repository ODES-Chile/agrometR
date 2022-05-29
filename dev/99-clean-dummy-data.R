library(tidyverse)

# estaciones --------------------------------------------------------------
dest <- readRDS("data/dummy/Estaciones_INIA.rds")

glimpse(dest)

dest <- dest %>%
  as_tibble() %>%
  mutate(primer_dato = lubridate::ymd_hms(primer_dato)) %>%
  mutate_at(vars(comuna_codigo, region_codigo, latitud, longitud, elevacion), as.numeric)

glimpse(dest)

saveRDS(dest, "data/dummy/estaciones.rds")

# datos -------------------------------------------------------------------
datos <- readRDS("data/dummy/data_estaciones.rds")

glimpse(datos)

datos <- datos %>%
  mutate(tiempo = lubridate::ymd_hm(tiempo))

glimpse(datos)

datos %>% count(station)

datos <- dest %>%
  count(nombre) %>%
  pull(nombre) %>%
  purrr::map_df(function(nm = "Belén"){

    message(nm)

    datos %>%
      mutate(
        station = nm,
        valor = valor + runif(nrow(.), 0, 10)
        )


  })

saveRDS(datos, "data/dummy/dtiempo.rds")


