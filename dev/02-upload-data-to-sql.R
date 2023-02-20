# setup -------------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(pool)
library(RPostgres)

TBL_datos      <- "estaciones_datos"
TBL_estaciones <- "estaciones"

con <- RPostgres::dbConnect(
  RPostgres::Postgres(),
  host =  Sys.getenv("HOST"),
  user = "shiny",
  password = Sys.getenv("SHINY_PSQL_PWD"),
  dbname = "shiny"
)

DBI::dbListTables(con)

# DBI::dbWriteTable(con, "mtcars", mtcars, temporary = F, overwrite = T)


# data estaciones ---------------------------------------------------------
agrometR::estaciones_agromet |> glimpse()

est_ran <- agrometR::estaciones_agromet |>
  select(station_id = ema, nombre_estacion = nombre_ema, region, latitud, longitud) |>
  glimpse()

est_ran

agrometR::estaciones_dmc |> glimpse()

est_dmc <- agrometR::estaciones_dmc |>
  select(station_id = codigoNacional, nombre_estacion = nombreEstacion, region = NombreRegion,
         latitud, longitud) |>
  glimpse()

est_dmc

estaciones <- bind_rows(
  est_ran |> mutate(red = "ran", .before = 1),
  est_dmc |> mutate(red = "dmc", .before = 1)
) |>
  mutate(
    nombre_estacion = str_trim(nombre_estacion),
    nombre_estacion = snakecase::to_title_case(nombre_estacion)
    )

sample_n(estaciones, 10)

if(DBI::dbExistsTable(con, TBL_estaciones)) DBI::dbRemoveTable(con, TBL_estaciones)

DBI::dbWriteTable(
  con,
  TBL_estaciones,
  estaciones,
  temporary = F,
  append = DBI::dbExistsTable(con, TBL_estaciones)
)

beepr::beep(4)

Sys.sleep(2)

# data diaria -------------------------------------------------------------
files <- dir("dev", full.names = TRUE) |>
  str_subset("data-daily") |>
  map(dir, full.names = TRUE) |>
  unlist()

years <- files |>
  str_extract("/[0-9]{4}") |>
  str_remove("/") |>
  unique() |>
  as.numeric() |>
  sort(decreasing = TRUE)

# years <- years[years >= 2020]

if(DBI::dbExistsTable(con, TBL_datos)) DBI::dbRemoveTable(con, TBL_datos)

Sys.sleep(2)

walk(years, function(year = 2021){

  figletr::figlet(year)

  files_year <- str_subset(files, str_c(year, "[0-9]{2}\\.rds"))

  files_year <- set_names(files_year, files_year)

  data_year <- map_df(files_year, readRDS, .id = "red") |>
    mutate(
      red = case_when(
        str_detect(red, "agromet") ~ "ran",
        str_detect(red, "dmc")     ~ "dmc",
        TRUE ~ NA_character_
        ),
      fecha_hora = as_date(fecha_hora)
    )

  data_year

  DBI::dbWriteTable(
    con,
    TBL_datos,
    data_year,
    temporary = F,
    append = DBI::dbExistsTable(con, TBL_datos)
    )

})

Sys.sleep(2)

RPostgres::dbDisconnect(con)

beepr::beep(4)

# test 1 ------------------------------------------------------------------
sql_con <- function() {
  dbPool(
    drv = Postgres(),
    host =  Sys.getenv("HOST"),
    user = "shiny",
    password = Sys.getenv("SHINY_PSQL_PWD"),
    dbname = "shiny"
  )
}

tbl(sql_con(), "estaciones_datos") |>
  count()

tbl(sql_con(), "estaciones_datos") |>
  glimpse()

dtest <- tbl(sql_con(), "estaciones_datos") |>
  filter(station_id == 20, red == "ran", year(fecha_hora) == 2022) |>
  select(fecha_hora, temp_promedio_aire) |>
  collect()

glimpse(dtest)

ggplot(dtest) +
  geom_line(aes(fecha_hora, temp_promedio_aire))


VAR <- "temp_promedio_aire"

tbl(sql_con(), "estaciones_datos") |>
  filter(station_id == 20, red == "ran", year(fecha_hora) == 2022) |>
  select(fecha_hora, "valor" = !!VAR) |>
  collect() |>
  ggplot() +
  geom_line(aes(fecha_hora, valor))

VAR <- "humed_rel_promedio"

tbl(sql_con(), "estaciones_datos") |>
  filter(station_id == 20, red == "ran", year(fecha_hora) == 2015) |>
  select(fecha_hora, "valor" = VAR) |>
  collect() |>
  ggplot() +
  geom_line(aes(fecha_hora, valor))

tbl(sql_con(), "estaciones_datos") |>
  count(y = year(fecha_hora)) |>
  collect() |>
  arrange(y)


