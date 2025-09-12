## Data Retrieval

The sections below outline the workflow for accessing lidar point cloud data from the OpenTopography bulk download S3 buckets and the USGS EPT (Entwine Point Tile) service, reprojecting it to a common coordinate system, and tiling the data into manageable tiles.

## Option 1: USGS EPT via Jupyter Notebook

For retriving a region-of-interest via the Entwine Point Tile (EPT) protocol, the `notebooks/intersection_data_retriever.ipynb` notebook automates all steps. Follow this workflow:

1. **Boundary Loading**  
   Read the USGS 3DEP boundary definitions (EPSG:4326) from:  
   ```text
   data/usgs_3dep_boundaries.geojson

This file is included in this repository under `data/usgs_3dep_boundaries.geojson`.
The most up-to-date version of the file can be found at:
[https://github.com/OpenTopography/Data\_Catalog\_Spatial\_Boundaries/blob/main/usgs\_3dep\_boundaries.geojson](https://github.com/OpenTopography/Data_Catalog_Spatial_Boundaries/blob/main/usgs_3dep_boundaries.geojson)

2. **Intersection Computation**  
   The notebook reads the two named collections (for example, `"CA PlacerCo 2012"` and `"USGS LPC CA NoCAL Wildfires B5a 2018"`) and clips the collections to their overlapping footprint.  
   The resulting polygon is written automatically to:  
   ```text
   data/placer_intersection.geojson

3. **Tile Grid Generation**  
   The notebook takes the clipped intersection polygon and automatically:  
   - Reprojects it to the configured UTM zone (e.g., EPSG:32610 for UTM Zone 10, spanning the west coast of North America).  
   - Tiles the dataset to a 1000 m tile width with an additional 20 m buffer.  
   - Writes the resulting grid of buffered tiles to:  
     ```text
     data/placer_tile_grid.geojson
     ```  
   Buffering ensures seamless coverage when tiles are processed independently.

4. **EPT Download**  
   Using the tile grid in `placer_tile_grid.geojson`, the notebook loops over each tile and:  
   - Invokes PDAL’s EPT reader to fetch the point cloud datasets  within the buffered polygon.  
   - Reprojects points to the target CRS.  
   - Saves each nonempty tile as a `.laz` file under:  
     ```text
     data/Placer_2012_Tiled/
     ```  
   An identical folder (`Placer_2018_Tiled`) is created for the second collection.  

#### Example parameters

````markdown
In the first cell of `intersection_data_retriever.ipynb`, verify and edit the following parameters:

```python
boundaries_geojson   = "data/usgs_3dep_boundaries.geojson"
name_a               = "CA PlacerCo 2012"
name_b               = "USGS LPC CA NoCAL Wildfires B5a 2018"
intersection_geojson = "data/placer_intersection.geojson"
tile_grid_geojson    = "data/placer_tile_grid.geojson"

ept_url_a            = "ept://s3-us-west-2.amazonaws.com/usgs-lidar-public/CA_PlacerCo_2012"
ept_url_b            = "ept://s3-us-west-2.amazonaws.com/usgs-lidar-public/USGS_LPC_CA_NoCAL_Wildfires_B5a_2018"

tile_size            = 1000    # meters
buffer_size          = 20      # meters
target_epsg          = "EPSG:32610"
````

**Parameter explanations:**

* `boundaries_geojson`
  Path to the GeoJSON file containing USGS 3DEP boundary polygons (EPSG:4326).

* `name_a`, `name_b`
  Exact `name` fields of the two collections to intersect. These must match entries in the boundaries GeoJSON.

* `intersection_geojson`
  Output path for the clipped intersection polygon. The next steps use this to define the area of interest.

* `tile_grid_geojson`
  Output path for the buffered, regular-grid GeoJSON defining each tile's footprint.

* `ept_url_a`, `ept_url_b`
  EPT endpoints for the two collections. Copy these from the USGS 3DEP portal; they tell PDAL where to fetch each dataset.

* `tile_size`
  Side length of each square tile, in projected units (meters). Controls the resolution of the tile grid.

* `buffer_size`
  Distance (in meters) to pad each tile's extent on all sides. Prevents missing edge points when tiles are processed independently.

* `target_epsg`
  EPSG code for the target projection (UTM zone). Use the code corresponding to your region (e.g., "32610" for UTM zone 10N).

---

After editing, run the notebook sections in the same order as the cells:

1. **Boundary Loading**
2. **Intersection Computation**
3. **Tile Grid Generation**
4. **EPT Download**

When complete, verify that `Placer_2012_Tiled/` (and `Placer_2018_Tiled/`) contain `.laz` files named by their lower‑left coordinates in the local UTM zone (for example, `500000_4200000.laz`).





## Option 2: AWS S3 (OpenTopography)

OpenTopography hosts lidar data collections on Cloud Oject Storage and are accessible via S3 CLI. The steps below show how to find the correct bucket address, verify its contents, and download all files to a local folder.

#### Tahoe National Forest 2013

1. **Find the bucket address**

   * On the OpenTopography website (https://opentopography.org), open the Tahoe National Forest 2013 lidar dataset page (https://portal.opentopography.org/lidarDataset?opentopoID=OTLAS.032017.26910.1).
   * In the "Data Access" or "Download Options" section, copy the S3 URI. It looks like:

     ```text
     s3://pc-bulk/CA13_Guo/
     ```
   * Bucket names usually match the dataset title with spaces replaced by underscores (e.g., `Tahoe_National_Forest_2013`), or use a provider shorthand like `CA13_Guo`.

2. **Check bucket contents**

   ```bash
   aws s3 ls s3://pc-bulk/CA13_Guo/ \
     --endpoint-url https://opentopography.s3.sdsc.edu \
     --no-sign-request
   ```

   * `aws s3 ls`: lists files in the bucket
   * `--endpoint-url`: points to OpenTopography’s S3 gateway
   * `--no-sign-request`: allows access without AWS credentials
     A list of `.laz` filenames confirms that the address is correct.

3. **Download all LAZ files**

   ```bash
   aws s3 cp s3://pc-bulk/CA13_Guo/ \
     "C:/Users/sreeja/Documents/Tahoe_National_Park/USFS_Tahoe_National_2013" \
     --recursive \
     --endpoint-url https://opentopography.s3.sdsc.edu \
     --no-sign-request
   ```

   * `aws s3 cp <source> <destination>`: copies files from the S3 bucket to the local folder
   * `--recursive`: downloads every file and subfolder
     After completion, the local folder contains all `.laz` files from the bucket.

#### Tahoe National Forest 2014

Repeat the same steps for the 2014 dataset, replacing the bucket URI and local folder path:

```bash
aws s3 ls s3://pc-bulk/CA14_Guo/ \
  --endpoint-url https://opentopography.s3.sdsc.edu \
  --no-sign-request

aws s3 cp s3://pc-bulk/CA14_Guo/ \
  "USFS_Tahoe_National_2014" \
  --recursive \
  --endpoint-url https://opentopography.s3.sdsc.edu \
  --no-sign-request
```

---

## Common Steps

### 1. Reprojection with LAS2LAS

The laz point clouds files can sometimes be stored in geographic coordinates (latitude/longitude), which can lead to inconsistent distance measurements. Reprojecting to the datasets to the same local UTM zone ensures that coordinates are expressed in meters and can be differenced following our workflow.

```bash
las2las \
  -i "USFS_Tahoe_National_2013/*.laz" \
  -odir "USFS_Tahoe_National_2013_reproj" \
  -olaz \
  -epsg 32610
```

* `-olaz`: maintain LAZ compression
* `-epsg`: target CRS (e.g., `32610` for UTM zone 10N)
* Adjust `32610` to the correct `326XX` code for your region.

---

### 2. CRS Workflow

Determine the UTM zone based on longitude:

1. Compute zone:

   ```
   zone = floor((longitude + 180) / 6) + 1
   ```
2. Northern Hemisphere EPSG codes: `326<zone>` (e.g., zone 10 → `32610`).
3. Southern Hemisphere codes: `327<zone>`.

Refer to a UTM zone map to confirm the correct zone for each dataset.

---

### 3. Tiling with LASTile

Tile or break large laz files into 1000 m x 1000 m tiles with a 10 m buffer for edge continuity:

```bash
lastile \
  -i "USFS_Tahoe_National_2013_reproj/*.laz" \
  -tile_size 1000 \
  -buffer 10 \
  -odir "USFS_Tahoe_National_Tiled_2013" \
  -olaz \
  -cores 4
```

* `-tile_size`: tile edge length in meters
* `-buffer`: overlap in meters
* `-cores`: parallel processes

> **Special case - already tiled & buffered LAS files**
> If the files are already tiled and buffered, we still recommend that you merge the tiles and then re-tile them using the scipt or the command.
> For example, if the tiles are in `.las` format, to merge the file before re-tiling, use `lasmerge`:
>
> ```bash
> lasmerge ^
>   -i "Kaibab\Mangum\*.las" ^
>   -o "Kaibab\Merged\Mangum_Merged.laz" ^
>   -olaz
> ```
>
> After merging, `lastile`can be run again especially if a different grid size or buffer is needed.

#### Notebook fallback

If `lastile` errors in the terminal, open the tiling notebook:

```bash
jupyter lab notebooks/tiling.ipynb
```

Edit the top-cell parameters (`input_dir`, `output_dir`, `tile_size`, `buffer`, `cores`), then run the **Tiling LAZ files** cell to process all files.

---


### 4. Configuration

In `intersection_data_retriever.ipynb` and any scripts, update paths and parameters:

```python
# Example for intersection notebook
boundaries_geojson   = "data/usgs_3dep_boundaries.geojson"
ept_url_a            = "ept://…/CA_PlacerCo_2012"
tile_size            = 1000
buffer_size          = 20
target_epsg          = "EPSG:32610"
```

Ensure that all directory paths match your local setup.

---

### 5. Scripts & Notebooks

* **notebooks/intersection\_data\_retriever.ipynb** - Clips boundaries, computes intersections, generates tile grids, and downloads EPT data.
* **notebooks/tiling.ipynb** - Automates LAS tiling via notebook cells.
  

> This work is part of the OpenForest4D project and is supported by funding from the National Science Foundation through awards 2409885, 2409886, and 2409887.

