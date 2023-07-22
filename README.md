# agrometR
Paquete R para descargar información de la Red Agroclimática Nacional

## Instalación :computer:

```r
devtools::install_github('ODES-Chile/agrometR')
```

## Ejemplo de uso

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
get_agro_data(station_id = 1:10, "2020-11-30 01:00:00", "2020-12-15 01:00:00")
```
