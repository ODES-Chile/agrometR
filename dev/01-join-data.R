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

