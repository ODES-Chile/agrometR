# setup -------------------------------------------------------------------
library(tidyverse)

# data --------------------------------------------------------------------
# source("dev/00-data-raw-agromet.R")
# source("dev/00-data-raw-dmc.R")

ddmc <- readRDS("dev/data/dmc_diaria.rds")
dagr <- readRDS("dev/data/agromet_diaria.rds")

glimpse(ddmc)

glimpse(dagr)


dagr |>
  group_by(estacion_id) |>
  summarise(fecha_hora_min = min(fecha_hora)) |>
  arrange(fecha_hora_min) |>
  count(fecha_hora_min, sort = TRUE) |>
  View()



# join --------------------------------------------------------------------

data <- bind_rows(dagr, ddmc)

data

saveRDS(data, "../obssa-chile/data/data_diaria.rds")

beepr::beep(4)


# estaciones --------------------------------------------------------------
agrometR::estaciones_agromet |> glimpse()

est_agromet <- agrometR::estaciones_agromet |>
  select(codigo = ema, nombre_estacion = nombre_ema, region, latitud, longitud) |>
  glimpse()

est_agromet

agrometR::estaciones_dmc |> glimpse()

est_dmc <- agrometR::estaciones_dmc |>
  select(codigo = codigoNacional, nombre_estacion = nombreEstacion, region = NombreRegion,
         latitud, longitud) |>
  glimpse()

est_dmc

estaciones <- bind_rows(
  est_agromet |> mutate(red = "agromet", .before = 1),
  est_dmc     |> mutate(red = "dmc")
)

sample_n(estaciones, 10)

saveRDS(estaciones, "../obssa-chile/data/estaciones.rds")

beepr::beep(4)

