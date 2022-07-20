# setup -------------------------------------------------------------------
library(tidyverse)

library(pool)
library(RPostgres)

SHINY_PSQL_PWD="9a4XsQNfbmQhP3JmsWNZ"

con <- RPostgres::dbConnect(
  RPostgres::Postgres(),
  user = "shiny",
  # password = Sys.getenv("SHINY_PSQL_PWD"),
  password =  SHINY_PSQL_PWD,
  dbname = "shiny",
  host = "137.184.9.247"
)

DBI::dbListTables(con)

DBI::dbWriteTable(con, "mtcars", mtcars, temporary = F, overwrite = T)

RPostgres::dbDisconnect(con)

sql_con <- function() {
  dbPool(
    drv = Postgres(),
    dbname = "shiny",
    host = "137.184.9.247",
    user = "shiny",
    password = Sys.getenv("SHINY_PSQL_PWD")
  )
}


con <- sql_con()

dplyr::tbl(con, "mtcars") |>
  dplyr::filter(cyl == 4) |>
  dplyr::collect()
# filter(!!sym("cyl") == !!input$filter_cyl)

# data --------------------------------------------------------------------
# source("dev/00-data-raw-agromet.R")
# source("dev/00-data-raw-dmc.R")

# agroemt
glimpse(dfdiario)

dfdiario <- dfdiario |>
  rename(estacion_id = station_id) |>
  arrange(fecha_hora, estacion_id) |>
  mutate(fuente =  "agromet", .before = 1)

glimpse(dfdiario)

saveRDS(dfdiario, "dev/data/agromet_diaria.rds")

# dmc
glimpse(dfdiario)

dfdiario <- dfdiario |>
  arrange(fecha_hora, estacion_id) |>
  mutate(fuente =  "dmc", .before = 1)

saveRDS(dfdiario, "dev/data/dmc_diaria.rds")



ddmc <- readRDS("dev/data/dmc_diaria.rds")
dagr <- readRDS("dev/data/agromet_diaria.rds")

glimpse(ddmc)

glimpse(dagr)


dagr |>
  group_by(estacion_id) |>
  summarise(fecha_hora_min = min(fecha_hora)) |>
  arrange(fecha_hora_min) |>
  count(fecha_hora_min, sort = TRUE)

# join --------------------------------------------------------------------
data <- bind_rows(dagr, ddmc) |>
  as_tibble()

data <- rename(data, red = fuente)

data

saveRDS(data, "../obssa-chile/data/data_diaria.rds")

data <- data |>
  filter(lubridate::year(fecha_hora) >= 2020)

saveRDS(data, "../obssa-chile/data/data_diaria_202X.rds")

data <- data |>
  filter(lubridate::year(fecha_hora) >= 2022)

saveRDS(data, "../obssa-chile/data/data_diaria_2022.rds")

beepr::beep(4)


# estaciones --------------------------------------------------------------
agrometR::estaciones_agromet |> glimpse()

est_agromet <- agrometR::estaciones_agromet |>
  select(estacion_id = ema, nombre_estacion = nombre_ema, region, latitud, longitud) |>
  glimpse()

est_agromet

agrometR::estaciones_dmc |> glimpse()

est_dmc <- agrometR::estaciones_dmc |>
  select(estacion_id = codigoNacional, nombre_estacion = nombreEstacion, region = NombreRegion,
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

