# agrometR :sun_behind_rain_cloud:
Paquete R para descargar información de la Red Agroclimática Nacional

## Instalación :computer:

```r
devtools::install_github('ODES-Chile/agrometR')
```

## Ejemplo de uso :memo:

Obtener el listado de estaciones

```r
library(agrometR)
estaciones_agromet
# A tibble: 417 × 8
     ema institucion nombre_ema      comuna          region          latitud longitud fecha_de_alta      
   <dbl> <chr>       <chr>           <chr>           <chr>             <dbl>    <dbl> <dttm>             
 1     1 FDF         Azapa1          Arica           Arica y Parina…   -18.5    -70.2 2013-03-08 06:49:10
 2     2 FDF         Azapa2          Arica           Arica y Parina…   -18.5    -70.2 2013-03-08 06:49:10
 3     3 FDF         Tranque Lautaro Tierra Amarilla Atacama           -28.0    -70   2013-03-08 06:49:12
 4     4 FDF         Jotabeche       Tierra Amarilla Atacama           -27.6    -70.2 2013-03-08 06:49:12
 5     5 FDF         Hornitos        Tierra Amarilla Atacama           -27.7    -70.2 2013-03-08 06:49:12
```

Descargar los datos para las estaciones con el código `ema` del 1 al 10, entre el 30 de noviembre al 15 de diciembre del año 2020.

```r
data <- get_agro_data(stations_id = 1:10, "2020-11-30 01:00:00", "2020-12-15 01:00:00")

library(dplyr)

data |>
  glimpse()
Rows: 3,610
Columns: 13
$ station_id            <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
$ fecha_hora            <dttm> 2020-11-30 01:00:00, 2020-11-30 02:00:00, 2020-11-30 03:00:00, 2020-11-3…
$ temp_promedio_aire    <dbl> 14.4, 13.8, 13.5, 14.2, 16.1, 15.8, 15.8, 19.4, 20.7, 20.8, 22.0, 23.2, 2…
$ precipitacion_horaria <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, …
$ humed_rel_promedio    <dbl> 86.0, 86.5, 87.8, 87.5, 77.8, 80.8, 82.0, 68.5, 65.5, 65.5, 62.5, 58.8, 5…
$ presion_atmosferica   <dbl> 1015.6, 1015.2, 1014.9, 1014.8, 1012.2, 1013.7, 1014.5, 1013.9, 1014.2, 1…
$ radiacion_solar_max   <dbl> 0, 0, 0, 0, 0, 21, 84, 130, 410, 538, 1056, 1039, 970, 902, 758, 652, 512…
$ veloc_max_viento      <dbl> 0.5, 0.5, 0.5, 0.5, 0.0, 0.5, 0.5, 0.9, 0.9, 2.7, 2.7, 2.7, 4.0, 2.7, 3.6…
$ temp_minima           <dbl> 14.4, 13.6, 13.3, 14.0, 15.8, 14.8, 14.6, 18.8, 19.9, 20.3, 21.7, 22.7, 2…
$ temp_maxima           <dbl> 14.5, 14.2, 13.8, 14.4, 16.4, 16.9, 18.5, 19.9, 21.5, 21.5, 22.2, 23.4, 2…
$ direccion_del_viento  <dbl> 0, 0, 0, 0, 317, 317, 317, 317, 304, 330, 310, 271, 301, 306, 302, 325, 2…
$ grados_dia            <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
$ horas_frio            <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
```
## Como citar

```md
 Kunst J, Zambrano F (2023). agrometR: For downloading meteorological data from the API of
  agromet. R package version 0.1.0, <https://github.com/ODES-Chile/agrometR>.
```
