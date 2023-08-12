# library(tidyverse)
# d <- agrometR::get_agro_data(1:50, "2021-11-30 01:00:00", "2021-12-15 01:00:00", verbose = TRUE)
# glimpse(d)
daily_aggregation_ran <- function(d){

  ddiario <- d |>
    dplyr::mutate(fecha_hora = lubridate::floor_date(.data$fecha_hora, "day"), .before = 1) |>
    dplyr::mutate(
      u_wind = .data$veloc_max_viento * sin(2 * pi * .data$direccion_del_viento  / 360),
      v_wind = .data$veloc_max_viento * cos(2 * pi * .data$direccion_del_viento  / 360)
    ) |>
    dplyr::group_by(.data$station_id, .data$fecha_hora) |>
    dplyr::summarise(
      .groups = "drop",
      temp_promedio_aire    = mean(.data$temp_promedio_aire, na.rm = TRUE),
      precipitacion_horaria = sum(.data$precipitacion_horaria, na.rm = TRUE),
      humed_rel_promedio    = mean(.data$humed_rel_promedio, na.rm = TRUE),
      presion_atmosferica   = mean(.data$presion_atmosferica, na.rm = TRUE),
      radiacion_solar_max   = mean(.data$radiacion_solar_max, na.rm = TRUE),
      veloc_max_viento      = max(.data$veloc_max_viento, na.rm = TRUE), # REVISAR
      temp_minima           = min(.data$temp_minima, na.rm = TRUE),
      temp_maxima           = max(.data$temp_maxima, na.rm = TRUE),
      direccion_del_viento  = mean(.data$direccion_del_viento, na.rm = TRUE), # REVISAR
      grados_dia            = NA,
      horas_frio            = NA,
      u_wind = mean(.data$u_wind, na.rm = TRUE),
      v_wind = mean(.data$v_wind, na.rm = TRUE)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      veloc_viento = sqrt(.data$u_wind ^ 2 + .data$v_wind ^ 2),
      direc_viento = ifelse(
        atan2(.data$u_wind, .data$v_wind) * 180 / pi >= 180,
        atan2(.data$u_wind, .data$v_wind) * 180 / pi - 180,
        atan2(.data$u_wind, .data$v_wind) * 180 / pi + 180
      )
    ) |>
    dplyr::select(-.data$u_wind, - .data$v_wind)

  ddiario

}

# d <- agrometR::get_agro_data_dmc(c(230004, 220002), "2020-11-30 01:00:00", "2020-12-15 01:00:00", verbose = TRUE)
# dplyr::glimpse(d)
daily_aggregation_dmc <- function(d){

  ddiario <- d |>
    dplyr::mutate(fecha_hora = lubridate::floor_date(.data$momento, "day"), .before = 1) |>
    dplyr::mutate(
      # REVISAR Fuerza a velocidad
      u_wind = .data$fuerzaDelVientoPromedio10Minutos * sin(2 * pi * .data$direccionDelVientoPromedio10Minutos / 360),
      v_wind = .data$fuerzaDelVientoPromedio10Minutos * cos(2 * pi * .data$direccionDelVientoPromedio10Minutos / 360)
    ) |>
    dplyr::group_by(.data$station_id, .data$fecha_hora) |>
    dplyr::summarise(
      .groups = "drop",
      temp_promedio_aire    = mean(.data$temperatura, na.rm = TRUE),
      precipitacion_horaria = max(.data$aguaCaida24Horas, na.rm = TRUE), # Revisado por Joaquin!
      humed_rel_promedio    = mean(.data$humedadRelativa, na.rm = TRUE),
      presion_atmosferica   = mean(.data$presionEstacion, na.rm = TRUE), # REVISAR
      radiacion_solar_max   = mean(.data$radiacionGlobalInst, na.rm = TRUE), # REVISAR
      veloc_max_viento      = max(.data$fuerzaDelVientoPromedio10Minutos, na.rm = TRUE), # REVISAR
      temp_minima           = min(.data$temperatura, na.rm = TRUE), # REVISAR
      temp_maxima           = max(.data$temperatura, na.rm = TRUE), # REVISAR
      direccion_del_viento  = mean(.data$direccionDelViento), # REVISAR
      grados_dia            = NA,
      horas_frio            = NA,
      u_wind = mean(.data$u_wind),
      v_wind = mean(.data$v_wind)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      veloc_viento = sqrt(.data$u_wind ^ 2 + .data$v_wind ^ 2),
      direc_viento = ifelse(
        atan2(.data$u_wind, .data$v_wind) * 180 / pi >= 180,
        atan2(.data$u_wind, .data$v_wind) * 180 / pi - 180,
        atan2(.data$u_wind, .data$v_wind) * 180 / pi + 180
      )
    ) |>
    dplyr::select(-.data$u_wind, - .data$v_wind)

  # glimpse(ddiario)

  ddiario

}
