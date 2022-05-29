# 1 -----------------------------------------------------------------------
library(leaflet)
library(leafem)
library(stars)

tif = system.file("tif/L7_ETMs.tif", package = "stars")
x1 = read_stars(tif)
x1 = x1[, , , 3] # band 3

plot(x1)

plot(image)

leaflet() |>
  addTiles() |>
  leafem:::addGeoRaster(
    x1
    , opacity = 0.9
    , colorOptions = colorOptions(
      palette = grey.colors(256)
    )
  )




# 2 -----------------------------------------------------------------------
library(leaflet)
library(leafem)
library(stars)
# install.packages('leaflet.extras2')

chrpsfl_04 = "https://data.chc.ucsb.edu/products/CHIRPS-2.0/africa_monthly/tifs/chirps-v2.0.2020.04.tif.gz"
chrpsfl_05 = "https://data.chc.ucsb.edu/products/CHIRPS-2.0/africa_monthly/tifs/chirps-v2.0.2020.05.tif.gz"

dsn_04 = file.path(tempdir(), basename(chrpsfl_04))
dsn_05 = file.path(tempdir(), basename(chrpsfl_05))

download.file(chrpsfl_04, dsn_04)
download.file(chrpsfl_05, dsn_05)

tiffl_04 = gsub(".gz", "", dsn_04)
R.utils::gunzip(dsn_04, tiffl_04)

tiffl_05 = gsub(".gz", "", dsn_05)
R.utils::gunzip(dsn_05, tiffl_05)

pal = hcl.colors(256, "inferno")
brks = seq(0, 1000, 10)

myCustomJSFunc = htmlwidgets::JS(
  "
    pixelValuesToColorFn = (raster, colorOptions) => {
      const cols = colorOptions.palette;
      var scale = chroma.scale(cols);

      if (colorOptions.breaks !== null) {
        scale = scale.classes(colorOptions.breaks);
      }
      var pixelFunc = values => {
        let clr = scale.domain([raster.mins, raster.maxs]);
        if (isNaN(values)) return colorOptions.naColor;
        if (values < 120) return colorOptions.naColor;
        return clr(values).hex();
      };
      return pixelFunc;
    };
  "
)

pal = hcl.colors(256, "inferno")
brks = seq(0, 1000, 10)

## add 2 layers to 2 custom panes - doesn't work, both rendered on pane from last call
leaflet() |>
  addTiles() |>
  addMapPane("left", 200) |>
  addMapPane("right", 201) |>
  addProviderTiles(
    "CartoDB.DarkMatter"
    , group = "carto_left"
    , options = tileOptions(pane = "left")
    , layerId = "leftid"
  ) |>
  addProviderTiles(
    "CartoDB.DarkMatter"
    , group = "carto_right"
    , options = tileOptions(pane = "right")
    , layerId = "rightid"
  ) |>
  leafem:::addGeotiff(
    file = tiffl_04
    , group = "april"
    , layerId = "april_id"
    , resolution = 96
    , opacity = 1
    , options = tileOptions(
      pane = "left"
    )
    , colorOptions = leafem:::colorOptions(
      palette = pal
      , breaks = brks
      , na.color = "transparent"
    )
    , pixelValuesToColorFn = myCustomJSFunc
  ) |>
  leafem:::addGeotiff(
    file = tiffl_05
    , group = "may"
    , layerId = "may_id"
    , resolution = 96
    , opacity = 1
    , options = tileOptions(
      pane = "right"
    )
    , colorOptions = leafem:::colorOptions(
      palette = pal
      , breaks = brks
      , na.color = "transparent"
    )
    , pixelValuesToColorFn = myCustomJSFunc
  ) |>
  leaflet.extras2::addSidebyside(
    layerId = "sidebyside"
    , leftId = "leftid"
    , rightId = "rightid"
  ) |>
  addLayersControl(overlayGroups = c("april", "may")) |>
  addControl(htmltools::HTML("April 2020"), position = "bottomleft") |>
  addControl(htmltools::HTML("May 2020"), position = "bottomright")
