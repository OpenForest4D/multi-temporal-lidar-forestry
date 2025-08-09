library(lidR)
library(fs)
library(future)

plan(multisession, workers = 4)

# Ground classification algorithm
algo <- pmf(ws = 5, th = 3)

# Input folders
input_folders <- c(
  "C:/Users/sreeja/Documents/Kaibab/Castle_Tiled",
  "C:/Users/sreeja/Documents/Kaibab/Ikes_Tiled",
  "C:/Users/sreeja/Documents/Kaibab/Mangum_Tiled"
)

# Output base
output_base <- "C:/Users/sreeja/Documents/Kaibab"

for (folder in input_folders) {
  folder_name <- path_file(folder)
  out_folder <- file.path(output_base, paste0("Reclassified_", folder_name))
  dir_create(out_folder)
  
  ctg <- readLAScatalog(folder)
  opt_chunk_size(ctg) <- 0  # Use file-based chunks (since these are already tiled)
  opt_chunk_buffer(ctg) <- 0
  opt_independent_files(ctg) <- TRUE
  opt_output_files(ctg) <- "" 
  
  catalog_apply(ctg, function(cluster, algo, out_folder) {
    in_file <- attr(cluster, "files")[1]
    tile_name <- basename(in_file)
    out_file <- file.path(out_folder, tile_name)
    
    if (file.exists(out_file)) {
      message("Skipping (already exists): ", tile_name)
      return(NULL)
    }
    
    las <- tryCatch(readLAS(cluster), error = function(e) {
      message("[Error] Failed to read: ", e$message)
      return(NULL)
    })
    
    if (is.null(las) || npoints(las) == 0) {
      message("[Warning] Empty or unreadable tile: ", tile_name)
      return(NULL)
    }
    
    las <- classify_ground(las, algorithm = algo)
    writeLAS(las, out_file)
    message(" -> Saved: ", tile_name)
    return(TRUE)
  }, algo = algo, out_folder = out_folder)
}
