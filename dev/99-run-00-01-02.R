library(tidyverse)

# 1. descarga ran/dmc raw data borrando los dos ultimos meses
# 2. borra los dos ultimos meses dmc/ran dailies y los genera
# 3. borra toda la bbdd y sube dailies

# c(
#   "dev/00-download-data-raw-monthly-agromet.R",
#   "dev/01-daily-aggregation-agromet.R"
#   ) |>
#   purrr::walk(source, echo = TRUE, encoding = "UTF-8")

c(
  "dev/00-download-data-raw-monthly-dmc.R",
  "dev/01-daily-aggregation-dmc.R"
) |>
  purrr::walk(source, echo = TRUE, encoding = "UTF-8")


# c(
#   # "dev/00-download-data-raw-monthly-agromet.R",
#   # "dev/00-download-data-raw-monthly-dmc.R",
#   "dev/01-daily-aggregation-agromet.R",
#   "dev/01-daily-aggregation-dmc.R"
#   # "dev/02-upload-data-to-sql.R"
# ) |>
#   purrr::walk(source, echo = TRUE, encoding = "UTF-8")
