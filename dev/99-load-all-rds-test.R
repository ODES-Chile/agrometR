library(tidyverse)
library(agrometR)

d <- dir("data/rds", full.names = TRUE) |>
  map_df(readRDS)

d |>
  nrow() |>
  scales::comma()

d |>
  summarise(across(.cols = fecha_hora, .fns = list(min = min, max = max)))

d |> count(station_id) |> count()

dr <- d |>
  group_by(station_id) |>
  summarise(across(.cols = fecha_hora, .fns = list(min = min, max = max))) |>
  left_join(estaciones_agromet, by = c("station_id" = "ema"))

dr

p <- ggplot(dr) +
  geom_segment(aes(
    y = as.character(station_id),
    yend = as.character(station_id),
    x = fecha_hora_min,
    xend = fecha_hora_max,
    color = institucion
  )) +
  scale_y_discrete(breaks = NULL) +
  scale_color_viridis_d(begin = 0.1, end = 0.9)

p

p + facet_wrap(vars(institucion))
p + facet_wrap(vars(region))


# estaciones_agromet |>
#   filter(region == "Magallanes")

# d |>
#   filter(fecha_hora == min(fecha_hora))

d |>
  filter(station_id == 11) |>
  select(-station_id) |>
  gather(key, value, -fecha_hora) |>
  ggplot(aes(fecha_hora, value)) +
  geom_line() +
  geom_smooth() +
  facet_wrap(vars(key), scales = "free")

