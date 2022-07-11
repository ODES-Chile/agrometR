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
  pivot_longer(cols = c(everything(), -codigo_estacion), names_to = "fecha", values_to = "precipitacion") |>
  mutate(
    precipitacion = na_if(precipitacion, -9999),
    fecha = str_remove(fecha, "-"),
    fecha = yyyymm::ym_to_date(fecha)
    )

data_historia

ggplot(data_historia) +
  geom_line(aes(fecha, precipitacion, group = codigo_estacion))

data_historia |>
  filter(is.na(precipitacion)) |>
  group_by(codigo_estacion) |>
  summarise(
    n_datos = n(),
    min(fecha),
    max(fecha)
  )

dmc_diaria |> count(estacion_id)
