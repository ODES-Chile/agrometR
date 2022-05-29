library(tidyverse)
library(agrometR)
library(lubridate)

FMT <- "%Y-%m-%d+%H:%M:%S"

mem_size_fmt <- function(el){
  utils:::format.object_size(pryr::object_size(el), "auto")
}


# Time intervals ----------------------------------------------------------
now <- Sys.time()
now

end <- floor_date(now, unit = "month") +
  days(-1) +
  hours(23) +
  minutes(59) +
  seconds(59)

end

starts <- c(
  # 1 month
  floor_date(end, unit = "month"),
  # 1 week
  end - days(6) - hours(23) - minutes(59) - seconds(59),
  # 1 day
  end - hours(23) - minutes(59) - seconds(59)
)

dtest <- tibble(
  start = starts,
  end = end + seconds(1)
)

dtest

# TEST one stations -------------------------------------------------------
rid <- sample(estaciones_agromet[["ema"]], 1)

dresults_id <- pmap_df(dtest, function(start = starts[3], end = end){

  message(str_glue("{start} - {end}"))

  t_start <- Sys.time()

  dres <- agrometR::get_agro_data(
    stations_id = rid,
    date_start = start,
    date_end = end,
    verbose = TRUE
  )

  t_end <- Sys.time()

  tibble(
    start = start,
    end = end,
    t_start = t_start,
    t_end = t_end,
    result = list(dres)
  )

})

dresults_id <- dresults_id |>
  mutate(
    diff = end - starts,
    time = t_end - t_start,
    n_download  = map_int(result, nrow),
    sec_by_row = time/n_download
  )

dresults_id

dresults_id$result

# TEST all stations -------------------------------------------------------
dresults_all <- pmap_df(dtest, function(start = starts[3], end = end){

  message(str_glue("{start} - {end}"))

  t_start <- Sys.time()

  dres <- agrometR::get_agro_data(
    estaciones_agromet[["ema"]],
    date_start = start,
    date_end = end,
    verbose = TRUE
    )

  t_end <- Sys.time()

  tibble(
    start = start,
    end = end,
    t_start = t_start,
    t_end = t_end,
    result = list(dres)
  )

})

dresults_all <- dresults_all |>
  mutate(
    diff = end - starts,
    time = t_end - t_start,
    n_download  = map_int(result, nrow),
    sec_by_row = time/n_download
  )

dresults_all

# raw data.frame ----------------------------------------------------------
d <- dresults_all$result[[1]]

d

mem_size_fmt(d)

# gather data.frame -------------------------------------------------------
dg <- d |>
  gather(key, value, -station_id, -fecha_hora)

dg

mem_size_fmt(dg)

# gather and removed NA data.frame ----------------------------------------
dgc <- dg |>
  filter(!is.na(value))

dgc

mem_size_fmt(dgc)

# gather, removed NA and convert key to factor data.frame -----------------
dgcf <- dg |>
  filter(!is.na(value)) |>
  mutate(key = factor(key))

dgcf

mem_size_fmt(dgcf)

# gather, removed NA, convert key to factor and spread data.frame ---------
dgcfs <- dg |>
  filter(!is.na(value)) |>
  mutate(key = factor(key)) |>
  spread(key, value)

dgcfs

mem_size_fmt(dgcfs)


d |>
  count(station_id, sort = TRUE)

dgcfs |>
  count(station_id, sort = TRUE)

dgcfs |>
  count(station_id, sort = TRUE) |>
  # tail()
  ggplot() +
  geom_histogram(aes(n))


# arrow -------------------------------------------------------------------
library(arrow)

arrow_dir <- "data/datarrow"

fs::dir_delete(arrow_dir)
fs::dir_create(arrow_dir)

dgcfs <- dgcfs |>
  mutate(
    # fecha = as_date(fecha_hora),
    mes = as_date(ceiling_date(fecha_hora, "month")),
    .before = 2
    )


dgcfs |>
  group_by(station_id, mes) |>
  write_dataset(arrow_dir, hive_style = FALSE)

saveRDS(dgcfs,"data/dgcfs.rds")

fs::file_info(arrow_dir) |> glimpse()
fs::file_info("data/dgcfs.rds") |> glimpse()



di <- starts[2]
di <- as_datetime(di)

darrow <- open_dataset(arrow_dir, partitioning = c("station_id", "mes"))

da <- darrow %>%
  filter(fecha_hora >= di) %>%
  filter(station_id == 309) %>%
  collect()



da |>
  filter(fecha_hora == min(fecha_hora)) |>
  pull(fecha_hora)

di


