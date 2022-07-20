# setup -------------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(pool)
library(RPostgres)

TBL <- "estaciones_datos"

con <- RPostgres::dbConnect(
  RPostgres::Postgres(),
  user = "shiny",
  password = Sys.getenv("SHINY_PSQL_PWD"),
  dbname = "shiny",
  host = "137.184.9.247"
)

DBI::dbListTables(con)

# DBI::dbWriteTable(con, "mtcars", mtcars, temporary = F, overwrite = T)

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

years <- years[years >= 2020]

if(DBI::dbExistsTable(con, TBL)) DBI::dbRemoveTable(con, TBL)

walk(years, function(year = 2021){

  message(year)

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
    TBL,
    data_year,
    temporary = F,
    append = DBI::dbExistsTable(con, TBL)
    )

})

RPostgres::dbDisconnect(con)

beepr::beep(4)



# test 1 ------------------------------------------------------------------
sql_con <- function() {
  dbPool(
    drv = Postgres(),
    dbname = "shiny",
    host = "137.184.9.247",
    user = "shiny",
    password = Sys.getenv("SHINY_PSQL_PWD")
  )
}

tbl(sql_con(), TBL) |>
  count()

tbl(sql_con(), TBL) |>
  glimpse()

dtest <- tbl(sql_con(), TBL) |>
  filter(station_id == 20, red == "ran", year(fecha_hora) == 2022) |>
  select(fecha_hora, temp_promedio_aire) |>
  collect()

glimpse(dtest)

ggplot(dtest) +
  geom_line(aes(fecha_hora, temp_promedio_aire))


VAR <- "temp_promedio_aire"

tbl(sql_con(), TBL) |>
  filter(station_id == 20, red == "ran", year(fecha_hora) == 2022) |>
  select(fecha_hora, "valor" = !!VAR) |>
  collect() |>
  ggplot() +
  geom_line(aes(fecha_hora, valor))

VAR <- "humed_rel_promedio"

tbl(sql_con(), TBL) |>
  filter(station_id == 20, red == "ran", year(fecha_hora) == 2022) |>
  select(fecha_hora, "valor" = VAR) |>
  collect() |>
  ggplot() +
  geom_line(aes(fecha_hora, valor))

