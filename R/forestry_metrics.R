# -------------------------------------------------------------------------------
# Lidar Metric Extraction Pipeline for OpenForest4D
# Project: OpenForest4D – NSF-funded research on multi-temporal Lidar forest analysis
# 
# Description:
# This R script defines and runs 'process_chm_pipeline()', an end-to-end automated
# function for processing pre-tiled Lidar point cloud datasets to generate:
#   - Digital Surface Models (DSM)
#   - Digital Terrain Models (DTM)
#   - Canopy Height Models (CHM)
#   - Hillshades (optional)
#   - Structural metrics: Rumple Index, Canopy Cover, Density >2m
# Each tile is processed in parallel using 'catalog_apply()' from the 'lidR' package.
#
# Required Input:
#   1. Tiled Lidar catalog folder (e.g., 1 km² tiles with overlap).
#   2. Geoid correction file (.gtx format) – optional but recommended.
#   3. Appropriate output directories with write access.
#
# Output:
#   Raster TIFFs for each metric saved in subfolders under the specified 'output_dir'.
#   Each raster is named by tile ID and year (e.g., 'tile_2018_dtm.tif').
#
# How to Use:
#   - Adjust the 'base_dir' to your input tile folder.
#   - Set the 'output_dir' to your desired output location.
#   - Provide a geoid file path if orthometric correction is needed.
#   - Set all required boolean flags for the metrics you want to compute.
#   - Optionally modify 'metric_res', 'size', and 'buffer' for grid resolution and tiling.
#   - Run the 'process_chm_pipeline()' function for each dataset/year.
#
# Dependencies:
#   - Required R libraries: 'lidR', 'terra', 'sf', 'future', 'geometry'
#   - You can install any missing libraries using:
#       install.packages("lidR")
#       install.packages("terra")
#       install.packages("sf")
#       install.packages("future")
#       install.packages("geometry")
#
# Note:
#   - If your geoid file is in '.tif' format, convert it to '.gtx' using:
#       gdalwarp -overwrite -s_srs EPSG:4326 -t_srs EPSG:32612 -r bilinear \
#         -of GTX geoid_18_CONUS.tif geoid_18_CONUS_save32612.gtx
#   - Ensure all paths use forward slashes or double backslashes ('\\') on Windows.
#   - This script assumes Lidar tiles are preprocessed, cleaned, and quality-checked.
#
# Documentation:
#   - For step-by-step usage instructions and project rationale, see the R_metrics.md file.
#   - The file includes a breakdown of the script and example outputs.


library(lidR)
library(terra)
library(future)
library(sf)
library(geometry)

plan(multisession, workers = 4)


process_chm_pipeline <- function(base_dir, output_dir, year,
                                 generate_dtm = TRUE,
                                 generate_dsm = TRUE,
                                 generate_chm = TRUE,
                                 generate_hillshade = FALSE,
                                 overwrite = TRUE,
                                 geoid_path = NULL,
                                 compute_rumple = FALSE,
                                 compute_canopy_cover = FALSE,
                                 compute_density_2m = FALSE,
                                 metric_res = 10,
                                 size = 1000,
                                 buffer = 20) {
  
  cat("\nStarting CHM processing for:", base_dir, "\n")
  start_all <- Sys.time()
  
  # ------------------------------------------------------------------------------
  # Set up output directories and configure the LAScatalog
  #
  # This section initializes the required folders for storing output rasters.
  # Each metric type (DTM, DSM, CHM, Rumple, Canopy Cover, Density >2m) gets
  # its own subdirectory within the provided 'output_dir', organized for clarity
  # and modularity.
  #
  # 'readLAScatalog(base_dir)' loads the entire set of tiled LAS/LAZ files into
  # a LAScatalog object, which enables efficient chunk-wise processing using
  # 'catalog_apply()'.
  #
  # The chunk size and buffer are set based on user-provided parameters.
  # These values determine how the input tiles are divided for parallel processing.
  #
  # - 'opt_chunk_size(ctg)': Defines the size (in meters) of each processing block.
  # - 'opt_chunk_buffer(ctg)': Adds an overlap (buffer) between chunks to reduce edge artifacts.
  # - 'opt_independent_files(ctg)': Ensures each tile is processed separately, avoiding cross-chunk dependencies.
  # - 'opt_output_files(ctg)': Left empty to avoid automatic writing; output is manually handled.
  #
  # ------------------------------------------------------------------------------
  
  dirs <- list(
    DTM_tiles = file.path(output_dir, "DTM_Tiles"),
    DSM_tiles = file.path(output_dir, "DSM_Tiles"),
    CHM_normalized_tiles = file.path(output_dir, "CHM_Tiles"),
    Rumple_tiles = file.path(output_dir, "Rumple_Tiles"),
    CanopyCover_tiles = file.path(output_dir, "Canopy_Cover_Tiles"),
    Density_Tiles = file.path(output_dir, "Density_Tiles")
  )
  lapply(dirs, dir.create, showWarnings = FALSE, recursive = TRUE)
  
  ctg <- readLAScatalog(base_dir)
  opt_chunk_size(ctg) <- size
  opt_chunk_buffer(ctg) <- buffer
  opt_independent_files(ctg) <- TRUE
  opt_output_files(ctg) <- ""
  
  
  # ------------------------------------------------------------------------------
  # Apply CHM Processing Pipeline to Each Tile in the Catalog
  #
  # This section defines and applies a custom processing function to each tile
  # (or "cluster") in the LAScatalog using 'catalog_apply()'. The function extracts
  # relevant Lidar metrics such as DSM, DTM, CHM, Rumple Index, Canopy Cover,
  # and Density >2m, and optionally applies hillshade rendering.
  #
  # ------------------------------------------------------------------------------
  
  catalog_apply(
    ctg,
    function(cluster,
             generate_dtm, generate_dsm, generate_chm,
             generate_hillshade, overwrite,
             compute_rumple, compute_canopy_cover, compute_density_2m,
             metric_res, year, geoid_path, dirs) {
      
      #Required libraries ('terra', 'lidR') are loaded explicitly to ensure availability in each worker session.
      library(terra) 
      library(lidR)
      
      #'toSpat()' is a helper function to convert 'grid_metrics' output into a'SpatRaster' object for consistency with Terra I/O.
      toSpat <- function(x) rast(x)
      
      # This helper function generates a hillshade raster from an input elevation raster
      # (typically a DSM, DTM, or CHM). Hillshading simulates topographic relief by using
      # illumination angles to enhance visual interpretation of terrain features.
      # It computes slope and aspect in radians, applies the shading algorithm,
      # and writes the result to a new GeoTIFF file with "_hillshade" suffix.
      hillshade_helper <- function(raster_path) {
        r  <- rast(raster_path)
        hs <- shade(
          terrain(r, v = "slope", unit = "radians"),
          terrain(r, v = "aspect", unit = "radians")
        )
        out_path <- gsub("\\.tif$", "_hillshade.tif", raster_path)
        writeRaster(hs, out_path, overwrite = TRUE)
      }
      
      # Attempt to load the LAS point cloud data for this tile using 'readLAS()'.
      # We wrap it in a tryCatch block to safely handle errors (e.g., corrupted or missing files).
      # If loading fails or the LAS file is empty, we return NULL to skip this tile gracefully.
      las <- tryCatch({
        readLAS(cluster)
      }, error = function(e) {
        message("[ERROR] Failed to read LAS tile: ", e$message)
        return(NULL)
      })
      
      if (is.null(las) || npoints(las) == 0) return(NULL)
      
      tile_path  <- attr(cluster, "files")[1]
      tile_name  <- tools::file_path_sans_ext(basename(tile_path))
      
      # ---------- output filenames ----------
      dtm_file  <- file.path(dirs$DTM_tiles, paste0(tile_name, "_", year, "_dtm.tif"))
      dsm_file  <- file.path(dirs$DSM_tiles, paste0(tile_name, "_", year, "_dsm.tif"))
      chm_file  <- file.path(dirs$CHM_normalized_tiles, paste0(tile_name, "_", year, "_chm.tif"))
      rumple_file <- file.path(dirs$Rumple_tiles, paste0(tile_name, "_", year, "_rumple.tif"))
      cc_file     <- file.path(dirs$CanopyCover_tiles, paste0(tile_name, "_", year, "_canopycover.tif"))
      d2_file     <- file.path(dirs$Density_Tiles, paste0(tile_name, "_", year, "_densitygt2m.tif"))
      
      message("[START] tile: ", tile_name)
      
      
      
      # ----------- DSM -----------
      # Generate the Digital Surface Model (DSM) for the current tile.
      # The DSM represents the elevation of the uppermost surfaces, including vegetation and structures,
      # and is derived from the Lidar point cloud using 'rasterize_canopy()' with the TIN algorithm.
      # The process is wrapped in a tryCatch block to catch any tile-specific errors.
      # 
      # After creation, the DSM is optionally corrected for geoid undulation by resampling and adding
      # a provided geoid raster. This step helps convert from ellipsoidal to orthometric heights.
      # 
      # The resulting DSM is saved to disk unless it already exists and overwriting is disabled.
      # If 'generate_hillshade' is enabled, a hillshade raster is also produced for visualization.
      
      dsm <- tryCatch({
        rasterize_canopy(las, res = 1, algorithm = dsmtin(max_edge = 3))
      }, error = function(e) {
        message("[ERROR] DSM generation failed: ", e$message)
        return(NULL)
      })
      
      if (is.null(dsm) || all(is.na(values(dsm)))) {
        message("[WARNING] DSM failed or empty for tile: ", tile_name)
        return(NULL)
      }
      
      if (!is.null(geoid_path) && file.exists(geoid_path)) {
        geoid <- rast(geoid_path)
        dsm   <- dsm + resample(geoid, dsm, method = "bilinear")
      }
      
      if (overwrite || !file.exists(dsm_file)) {
        writeRaster(dsm, dsm_file, overwrite = TRUE)
        if (generate_hillshade) hillshade_helper(dsm_file)
      }
      
      
      
      # ----------- DTM -----------
      # Generate the Digital Terrain Model (DTM) for the current tile.
      # The DTM models the bare earth surface by excluding vegetation, buildings, and other elevated features.
      # It is computed using 'rasterize_terrain()' with the TIN (Triangulated Irregular Network) algorithm,
      # which interpolates ground points to estimate the terrain surface.
      #
      # The computation is enclosed in a tryCatch block to ensure that any failures (e.g., due to poor data quality)
      # are logged without halting the entire pipeline.
      #
      # If the DTM is empty or invalid, the function skips further processing for this tile.
      dtm <- tryCatch({
        rasterize_terrain(las, res = 1, algorithm = tin())
      }, error = function(e) {
        message("[ERROR] DTM generation failed: ", e$message)
        return(NULL)
      })
      
      if (is.null(dtm) || all(is.na(values(dtm)))) {
        message("[WARNING] DTM failed or empty for tile: ", tile_name)
        return(NULL)
      }
      
      
      
      
      # ----------- Normalized CHM -----------
      # Generate the Canopy Height Model (CHM) by normalizing the original LAS point cloud.
      # First, heights in the LAS file are normalized using the DTM to reference all elevation values to ground level.
      # If no points remain after normalization (e.g., due to data errors or overly aggressive filtering), the tile is skipped.
      #
      # The CHM is then computed using 'rasterize_canopy()' with the TIN-based surface reconstruction algorithm ('dsmtin()'),
      # which interpolates the topmost points (e.g., tree canopy or roof surfaces) to form a continuous surface.
      # If the resulting CHM is invalid or empty, the tile is skipped.
      #
      # The CHM is masked using the DSM to ensure spatial consistency, especially in areas with poor returns.
      # If the output doesn't already exist or if overwriting is enabled, the CHM is saved.
      # Optionally, a hillshade image is generated to support better visualization of canopy structure.
      
      # Apply geoid correction to the DTM if a geoid file is provided.
      # The geoid adjustment accounts for the difference between ellipsoidal height (from the Lidar sensor)
      # and orthometric height (more appropriate for terrain analysis), improving elevation accuracy.
      # The geoid raster is resampled and added to the DTM using bilinear interpolation to match resolutions.
      #
      # The adjusted DTM is then masked by the DSM to preserve alignment and shape.
      # If the output doesn’t already exist or overwriting is enabled, the DTM is written to disk.
      # Optionally, a hillshade is also generated for visualization.
      
      las_norm <- normalize_height(las, dtm)
      if (npoints(las_norm) == 0) {
        message("[WARNING] Normalized LAS has zero points for tile: ", tile_name)
        return(NULL)
      }
      
      chm <- tryCatch({
        rasterize_canopy(las_norm, res = 1, algorithm = dsmtin())
      }, error = function(e) {
        message("[ERROR] CHM generation failed: ", e$message)
        return(NULL)
      })
      
      if (is.null(chm) || all(is.na(values(chm)))) {
        message("[WARNING] CHM failed or empty for tile: ", tile_name)
        return(NULL)
      }
      
      chm <- mask(chm, dsm)
      
      if (overwrite || !file.exists(chm_file)) {
        writeRaster(chm, chm_file, overwrite = TRUE)
        if (generate_hillshade) hillshade_helper(chm_file)
      }
      
      
      
      
      # ----------- DTM with Geoid -----------
      # Apply geoid correction to the DTM after generating the CHM.
      # This ordering ensures consistency in vertical referencing:
      # 
      # - The CHM is computed by subtracting the uncorrected DTM from the raw LAS elevation values.
      #   Since the LAS data is in ellipsoidal height, we must use an *uncorrected* DTM for CHM normalization—
      #   otherwise we’d be mixing orthometric and ellipsoidal references, which would distort canopy heights.
      #
      # - Once the CHM is finalized, the geoid correction is applied to the DTM to convert it to orthometric height.
      #   This corrected DTM is more suitable for further topographic analysis, terrain modeling, or integration with other geospatial datasets.
      #
      # The geoid raster is resampled to match the DTM’s resolution using bilinear interpolation and then added to the DTM.
      # The final geoid-adjusted DTM is masked to match the DSM footprint, ensuring consistent spatial coverage.
      #
      # If the output doesn't already exist or 'overwrite = TRUE', the DTM is written to disk.
      # A hillshade image is also generated if the 'generate_hillshade' flag is enabled.
      
      if (!is.null(geoid_path) && file.exists(geoid_path)) {
        geoid <- rast(geoid_path)
        dtm   <- dtm + resample(geoid, dtm, method = "bilinear")
      }
      
      dtm <- mask(dtm, dsm)
      
      if (overwrite || !file.exists(dtm_file)) {
        writeRaster(dtm, dtm_file, overwrite = TRUE)
        if (generate_hillshade) hillshade_helper(dtm_file)
      }
      
      
      
      
      # ---------- Rumple ----------
      # Compute the Rumple Index, which quantifies surface roughness or structural complexity of the canopy.
      #
      # This block first checks whether Rumple computation is requested ('compute_rumple == TRUE') and whether 
      # the output file already exists or should be overwritten.
      #
      # - We filter the point cloud to retain only surface points within 0.5 m of the top of the canopy.
      #   These are most relevant for capturing surface structure and eliminating noise from lower vegetation or ground returns.
      #
      # - If sufficient surface points are present, 'grid_metrics()' is used to compute the Rumple Index across tiles 
      #   at the specified resolution ('metric_res'). This function calculates the 3D surface area to 2D footprint area ratio.
      #
      # - The result is converted to a 'SpatRaster' object using the 'toSpat()' helper and saved to disk.
      #
      # If no surface points are available in the tile, a warning is issued and no output is written for that tile.
      
      if (compute_rumple && (!file.exists(rumple_file) || overwrite)) {
        las_surface <- filter_surfacepoints(las, 0.5)
        if (npoints(las_surface) > 0) {
          rumple <- toSpat(grid_metrics(las_surface, ~rumple_index(X, Y, Z), metric_res))
          writeRaster(rumple, rumple_file, overwrite = TRUE)
        } else {
          message("[WARNING] No surface points for Rumple in tile: ", tile_name)
        }
      }
      
      
      
      
      # ---------- Canopy Cover ----------
      # Compute Canopy Cover, which represents the proportion of ground covered by vegetation above a certain height threshold.
      #
      # This block runs only if 'compute_canopy_cover' is TRUE and the corresponding output file doesn't exist 
      # or needs to be overwritten.
      #
      # - We filter the normalized point cloud ('las_norm') to retain only first returns ('ReturnNumber == 1'), 
      #   as these best represent the uppermost surfaces (canopy tops) without being obscured by overstory.
      #
      # - For each grid cell (at resolution 'metric_res'), we calculate the ratio of first returns above 1 meter 
      #   (i.e., likely vegetation) to the total number of first returns. This gives a fractional measure of canopy cover.
      #
      # - The result is converted to a 'SpatRaster' and saved as a GeoTIFF.
      #
      # If no valid first returns are found for a tile, a warning is printed and no output is generated.
      
      if (compute_canopy_cover && (!file.exists(cc_file) || overwrite)) {
        first <- filter_poi(las_norm, ReturnNumber == 1)
        if (npoints(first) > 0) {
          cc <- toSpat(grid_metrics(first, ~sum(Z > 1) / length(Z), res = metric_res))
          writeRaster(cc, cc_file, overwrite = TRUE)
        } else {
          message("[WARNING] No first returns for Canopy Cover in tile: ", tile_name)
        }
      }
      
      
      
      
      # ---------- Density >2m ----------
      # Compute the vertical point density above 2 meters, representing the proportion of points in the canopy layer.
      #
      # This metric is useful for assessing the vertical structure and vegetation density—particularly for identifying 
      # mid-to-upper canopy biomass. It complements Canopy Cover by focusing on *point density* rather than *surface coverage*.
      #
      # This block executes only if 'compute_density_2m' is TRUE and the corresponding raster doesn't already exist 
      # (or needs to be overwritten).
      #
      # - The input point cloud is the normalized LAS ('las_norm'), where height Z is relative to the ground.
      #
      # - For each grid cell (based on 'metric_res'), we calculate the fraction of points whose normalized height exceeds 2 meters.
      #   This helps isolate true canopy elements from understory or ground clutter.
      #
      # - The output is written as a 'SpatRaster' GeoTIFF.
      #
      # If no valid points are found in the tile, the metric is skipped with a warning.
      
      if (compute_density_2m && (!file.exists(d2_file) || overwrite)) {
        if (npoints(las_norm) > 0) {
          d2 <- toSpat(grid_metrics(las_norm, ~sum(Z > 2) / length(Z), res = metric_res))
          writeRaster(d2, d2_file, overwrite = TRUE)
        } else {
          message("[WARNING] No points for Density >2m in tile: ", tile_name)
        }
      }
      
      message("[END]   tile: ", tile_name)
      
      TRUE
    },
    generate_dtm       = generate_dtm,
    generate_dsm       = generate_dsm,
    generate_chm       = generate_chm,
    generate_hillshade = generate_hillshade,
    overwrite          = overwrite,
    compute_rumple     = compute_rumple,
    compute_canopy_cover = compute_canopy_cover,
    compute_density_2m = compute_density_2m,
    metric_res         = metric_res,
    year               = year,
    geoid_path         = geoid_path,
    dirs               = dirs
  )
  
  cat("All processing completed!\n")
  cat("Total time:", round(difftime(Sys.time(), start_all, units = "mins"), 2), "minutes\n")
}


# ---------------------------------------------------------------------------
# Run the CHM processing pipeline for two different years: 2012 and 2018.
#
# This block invokes the full 'process_chm_pipeline()' function twice—once per year—
# to extract Lidar-derived structural metrics from two timepoints. These metrics
# will later be used to assess forest change over time.
#
# For each year:
# - 'base_dir' points to the folder containing tiled LAS/LAZ data.
# - 'output_dir' is where the derived rasters (DSM, DTM, CHM, etc.) will be saved.
# - 'year' tag ensures filenames include the correct timepoint.
# - 'generate_*' flags control which outputs are computed.
# - 'overwrite' allows existing outputs to be replaced.
# - 'geoid_path' provides the vertical correction grid for accurate elevation adjustment.
# - 'compute_*' flags enable the optional forest structure metrics (Rumple Index, Canopy Cover, Density >2m).
# - 'metric_res' sets the grid resolution (in meters) for rasterized summary outputs.
# - 'size' and 'buffer' configure the LAScatalog chunking behavior for parallel tile-based processing.
#
# Running this for both 2012 and 2018 ensures comparable metric rasters that can be
# differenced later to quantify structural changes in forest canopy over time.
# ---------------------------------------------------------------------------


process_chm_pipeline(
  base_dir = "C:/Users/sreeja/Documents/CA_Placer_Co/Placer_2012_Tiled",
  output_dir = "C:/Users/sreeja/Documents/CA_Placer_Co/extracted_2012_metrics",
  year = 2012,
  generate_dsm = TRUE,
  generate_dtm = TRUE,
  generate_chm = TRUE,
  generate_hillshade = TRUE,
  overwrite = TRUE,
  geoid_path = "C:/Users/sreeja/Desktop/geoids/geoid_12_CONUS_save32610.gtx",
  compute_rumple = TRUE,
  compute_canopy_cover = TRUE,
  compute_density_2m = TRUE,
  metric_res = 10,
  size = 1000,
  buffer = 20
)

process_chm_pipeline(
  base_dir = "C:/Users/sreeja/Documents/CA_Placer_Co/Placer_2018_Tiled",
  output_dir = "C:/Users/sreeja/Documents/CA_Placer_Co/extracted_2018_metrics",
  year = 2018,
  generate_dsm = TRUE,
  generate_dtm = TRUE,
  generate_chm = TRUE,
  generate_hillshade = TRUE,
  overwrite = TRUE,
  geoid_path = "C:/Users/sreeja/Desktop/geoids/geoid_18_CONUS_save32610.gtx",
  compute_rumple = TRUE,
  compute_canopy_cover = TRUE,
  compute_density_2m = TRUE,
  metric_res = 10,
  size = 1000,
  buffer = 20
)
