#' Get data directory
#' 
#' Find out where the environmental data is stored
#' 
#' @usage get_datadir(datadir)
#'   
#' @param datadir character. Directory as passed to \code{\link{load_layers}}.
#'   This does not change the data directory used by \code{\link{load_layers}}
#'   but only shows the result of passing a specific datadir. If \code{NULL} is
#'   passed then the \code{sdmpredictors_datadir} option is read. To set this
#'   run \code{options(sdmpredictors_datadir = "<your preferred directory>")} in
#'   every session or in your .RProfile.
#'   
#' @return Path to the data directory.
#' @seealso \code{\link{load_layers}}
#' @keywords internal
get_datadir <- function(datadir) {
  if(is.null(datadir)) {
    datadir <- getOption("sdmpredictors_datadir")
    if(is.null(datadir)) {
      datadir <- file.path(tempdir(), "sdmpredictors")
      warning("file.path(tempdir(), \"sdmpredictors\") will be used as datadir, set options(sdmpredictors_datadir=\"<directory>\") to avoid re-downloading the data in every session or set the datadir parameter in load_layers")
    } else {
      datadir <- normalizePath(paste0(datadir), winslash = "/", mustWork = NA)
    }
  }
  
  if(!dir.exists(datadir)) {
    dir.create(datadir, recursive = TRUE)
  }
  datadir
}

#' Project and saves a layer from WGS84 (EPGS:4326) to Behrmann Equal Area (ESRI:54017) coordinate reference system
#'
#' @usage equalarea_project(path)
#'
#' @param path the path to the WGS84 layer
#'
#' @return the path to the Behrmann Equal Area layer
#' @seealso  \code{\link{load_layers}}
#' @keywords internal
equalarea_project <- function(path){
  if(grepl(".zip", path, fixed = TRUE)){
    vsizip <- "/vsizip/"
    out_path <- gsub(".zip", ".tif", path, fixed = TRUE)
  }else{
    vsizip <- ""
    out_path <- gsub("_lonlat.tif", ".tif", path, fixed = TRUE)
  }
  stopifnot(out_path != path)
  if(!file.exists(out_path)){
    r <- raster::raster(paste0(vsizip, path))
    message(paste0("Projecting ", path, " from native WGS84 to Behrmann Equal Areas. This might take a few minutes."))
    if(grepl("/FW_", path, ignore.case = FALSE, fixed = TRUE)){res = 815}else{res = 7000} # Quickfix. Ideally: get res from .data
    out <- raster::projectRaster(r, crs = sdmpredictors::equalareaproj, method = "ngb", res = res)
    raster::writeRaster(out, out_path)
  }
  stopifnot(as.character(raster(out_path)@crs) == as.character(sdmpredictors::equalareaproj))
  return(out_path)
}

#' Load layers
#' 
#' Method to load rasters from disk or from the internet. By default a 
#' RasterStack is returned but this is only possible When all rasters have the 
#' same spatial extent and resolution.
#' 
#' @usage load_layers(layercodes, equalarea=FALSE, rasterstack=TRUE, 
#'   datadir=NULL)
#'   
#' @param layercodes character vector or dataframe. Layer_codes of the layers to
#'   be loaded or dataframe with a "layer_code" column.
#' @param equalarea logical. If \code{TRUE} then layers are loaded with a 
#'   Behrmann cylindrical equal-area projection (\code{\link{equalareaproj}}), 
#'   otherwise unprojected (\code{\link{lonlatproj}}). Default is \code{FALSE}.
#' @param rasterstack logical. If \code{TRUE} (default value) then the result is
#'   a \code{\link[raster]{stack}} otherwise a list of rasters is returned.
#' @param datadir character. Directory where you want to store the data. If 
#'   \code{NULL} is passed (default) then the \code{sdmpredictors_datadir} 
#'   option is read. To set this run \code{options(sdmpredictors_datadir="<your 
#'   preferred directory>")} in every session or add it to your .RProfile.
#'   
#' @return RasterStack or list of raster
#' @examples \dontrun{
#' # warning using tempdir() implies that data will be downloaded again in the 
#' # next R session
#' env <- load_layers("BO_calcite", datadir = tempdir())
#' }
#' @export
#' @seealso \code{\link{list_layers}}, \code{\link{layer_stats}}, 
#'   \code{\link{layers_correlation}}
load_layers <- function(layercodes, equalarea = FALSE, rasterstack = TRUE, datadir = NULL) {
  if(is.na(equalarea) || !is.logical(equalarea) || length(equalarea) != 1) {
    stop("equalarea should be TRUE or FALSE")
  }
  if(is.data.frame(layercodes)) {
    layercodes <- layercodes$layer_code
  }
  info <- get_layers_info(layercodes)
  counts <- table(info$common$time)
  if(length(unique(info$common$cellsize_equalarea)) > 1) {
    stop("Loading layers with different cellsize is not supported")
  } else if (sum(counts) != NROW(layercodes)) {
    layers <- info$common$layer_code
    stop(paste0("Following layer codes where not recognized: ", 
                paste0(layercodes[!(layercodes %in% layers)], collapse = ", ")))
  }
  if(max(counts) != NROW(layercodes)) {
    warning("Layers from different eras (current, future, paleo) are being loaded together")
  }
  if(gdal_is_lower_than_3()){
    warning("GDAL is lower than version 3. Consider updating GDAL to avoid errors.")
  }
  datadir <- get_datadir(datadir)
  get_layerpath <- function(layercode) {
    layer_url <- subset(info$common, info$common$layer_code == layercode)$layer_url
    if(grepl(".zip", layer_url, ignore.case = FALSE, fixed = TRUE)){
      ext <- "_lonlat.zip"
    }else{ext <- "_lonlat.tif"}
    path <- paste0(datadir, "/", layercode, ext)
    if(!file.exists(path)) {
      ok <- -1
      # clean up of download failed
      on.exit({
        if(ok != 0 && file.exists(path)) {
          file.remove(path)
        }
      })
      ok <- utils::download.file(layer_url, path, method = "auto", quiet = FALSE, mode = "wb")  
    }
    ifelse(file.exists(path), path, NA)
  }
  paths <- sapply(layercodes, get_layerpath)
  if(equalarea){
    customSupressWarning <- function(w){if(any(grepl( "point", w))){invokeRestart( "muffleWarning")}} 
    paths <- withCallingHandlers(sapply(paths, equalarea_project), warning = customSupressWarning)
  }
  if(rasterstack) {
    logical_zip <- grepl(".zip", paths, fixed = TRUE)
    if(all(logical_zip) | !any(logical_zip)){
      if(all(logical_zip)){
        vsizip <- "/vsizip/"
      }else if(!any(logical_zip)){
        vsizip <- ""
      }
      st <- raster::stack(paste0(vsizip, paths))
      if("layer" %in% names(st)){
        names(st) <- layercodes
      }else(
        names(st) <- sub("_lonlat$", "", names(st))
      )
      return(st)
    }else{
      stop("Rasterstack for zipped and non-zipped files not supported. Try `rasterstack = FALSE`")
    }
  } else {
    return(lapply(paths, function(path) { 
      if(grepl(".zip", path, fixed = TRUE)){
        vsizip <- "/vsizip/"
      }else{
        vsizip <- ""
      }
      r <- raster::raster(paste0(vsizip, path))
      if("layer" %in% names(r)){
        names(r) <- layercodes
      }else(
        names(r) <- sub("_lonlat$", "", names(r))
      )
      r}))
  }
}

#' Longitude/latitude coordinate reference system (EPSG:4326), used when using
#' load_layers with equal_area = FALSE
#' @export
lonlatproj <- sp::CRS("+proj=longlat +datum=WGS84 +no_defs")

#' World Behrmann equal area coordinate reference system (ESRI:54017), used when
#' using load_layers with equal_area = TRUE
#' @export
equalareaproj <- sp::CRS("+proj=cea +lon_0=0 +lat_ts=30 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs")

#' Is gdal v3 or more?
#' @noRd
gdal_is_lower_than_3 <- function(){
  vgdal <- terra::gdal()
  vgdal <- strsplit(vgdal, ".", fixed = TRUE)[[1]][1]
  vgdal <- as.numeric(vgdal)
  is_less_than_3 <- vgdal < 3
  is_less_than_3
}