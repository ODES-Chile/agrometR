library(tidyverse)

tfread <- compose(data.table::fread, as_tibble, .dir = "forward")

transpose_df <- function(df){
  df2 <- as_tibble(cbind(nms = names(df), t(df)))
  df2
}

fs <- dir("data-raw/cr2-precipitaciones", full.names = TRUE, recursive = TRUE)
fs


df <- tfread("data-raw/cr2-precipitaciones/cr2_prDaily_2020_ghcn/cr2_prDaily_2020_ghcn.txt")
df

df2 <- df |>
  transpose_df() |>
  select(-nms) |>
  janitor::row_to_names(row_number = 1) |>
  readr::type_convert()

datos_estaciones <- df2 |>
  select(1:inicio_automatica)


data_historia <- df2 |>
  select(codigo_estacion, `1900-01-01`:last_col()) |>
  pivot_longer(cols = c(everything(), -codigo_estacion), names_to = "fecha", values_to = "precipitacion")

data_historia <- data_historia |>
  mutate(
    precipitacion2 = na_if(precipitacion, -9999),
    fecha2 = lubridate::ymd(fecha)
    )

data_historia

data_historia |>
  filter(is.na(fecha2))

data_historia |>
  filter(is.na(precipitacion2)) |>
  count(precipitacion)

data_historia |>
  filter(is.na(as.numeric(codigo_estacion))) |>
  count(codigo_estacion)


data_historia_clean <- data_historia |>
  filter(!is.na(precipitacion2))

data_historia_clean |>
  filter(!is.na(precipitacion2)) |>
  group_by(codigo_estacion) |>
  summarise(
    n_datos = n(),
    min(fecha2),
    max(fecha2)
  )

agrometR::estaciones_dmc


datos_estaciones |> count(fuente)

datos_estaciones |>
  filter(is.na(as.numeric(codigo_estacion)))

datos_estaciones |>
  filter(!is.na(as.numeric(codigo_estacion)))

datos_estaciones |>
  filter(str_detect(codigo_estacion, "220002"))


