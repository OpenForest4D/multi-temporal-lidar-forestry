# OpenForest4D Lidar Processing Pipeline

This repository contains workflows for retrieving, processing, and analyzing multi‑temporal lidar data to detect structural changes to forests. The pipeline supports:

- **Data retrieval** from USGS EPT and OpenTopography S3  
- **Reprojection** and **tiling** of point clouds  
- **Extraction** of raster-based forest metrics (e.g., canopy height model, rumple index)  
- **Differencing** of DSM's, DTM's, canopy height models, canopy cover and rumple over time
- **Visualization** of topographic hillshades and change products via QGIS  

By standardizing each step in Jupyter notebooks and R scripts, the project ensures reproducibility, scalability, and ease of adaptation for new areas or time periods. This work is supported by the NSF‑funded OpenForest4D project.

---

## 1. Repository Structure

```

project-root/
├── data/                              # static assets
│   └── usgs\_3dep\_boundaries.geojson   # USGS 3DEP boundary definitions
├── notebooks/                         # Jupyter workflows
│   ├── intersection\_data\_retriever.ipynb  # EPT data retrieval & tiling
│   ├── tiling.ipynb                       # LASTile tiling fallback
│   ├── differencing\_script.ipynb          # Forest metrics differencing
│   └── forestry\_metrics.R                 ← R script for canopy metrics
├── scripts/                           # command‑line helpers
│   └── tile\_laz.py                    # Python wrapper for LASTile
├── environment.yml                    ← Conda environment spec
├── Data\_Retrieval\_Instructions.md     ← detailed data retrieval guide
├── README.md                          ← this file
├── LICENSE                            ← project license
└── CITATION.cff                       ← citation metadata

```

---

## 2. Installation & Setup

Refer to **Setup Instructions** for full details (see below or [Data_Retrieval_Instructions.md]).

1. **Clone repo**  
   ```bash
   git clone https://github.com/YourUser/OpenForest4D.git
   cd OpenForest4D
   ```

2. **Install Conda**

   * Download Anaconda or Miniconda and follow the prompts.
   * Open a Conda‑enabled prompt.

3. **Create environment**

   ```bash
   conda env create -f environment.yml
   conda activate lidar_env
   ```

4. **Verify packages**

   ```bash
   conda list
   ```

5. **Install RStudio** (for forestry metrics)

   * R 4.0+ from CRAN
   * RStudio Desktop
   * In R:

     ```r
     install.packages(c("terra","future","lidR"))
     ```

---

## 3. Workflow & How to Run

### Option 1: Data Retrieval (if raw LAZ not already available)
Check `Data_Retrieval_Instructions.md` for a more detailed guide.

* **Primary method:**
  Run `notebooks/intersection_data_retriever.ipynb` (USGS EPT).
* **Alternative S3:**
  Edit and run `Data_Retrieval_Instructions.md` steps for AWS S3.

### Option 2: Tiling

If point clouds exist but tiling is needed:

1. **Script:**

   ```bash
   python scripts/tile_laz.py \
     --input-dir <path_to_reproj> \
     --output-dir <path_to_tiles> \
     --tile-size 1000 \
     --buffer 20 \
     --cores 4
   ```
2. **Notebook fallback:**
   Open `notebooks/tiling.ipynb`, set `input_dir`, `output_dir`, `tile_size`, `buffer`, `cores`, then run the "Tiling LAZ files" cell.

### Step 1: Extract Forest Metrics

* **Why:** Derive canopy height, canopy cover, rumple index, and point density metrics for each tile.
* **Script:**
  Open `notebooks/forestry_metrics.R` in RStudio and run end‑to‑end.
* **Output:** GeoTIFF rasters (e.g., `CHM.tif`, `Rumple.tif`) saved under the same tile folder.

### Step 2: CHM Differencing

* **Why:** Compute pixel‑wise change between two dates to detect growth or disturbance.
* **Notebook:**
  `notebooks/differencing_script.ipynb` loads CHM rasters from two folders, calculates difference, and exports a difference GeoTIFF.
* **Output:** `CHM_Difference.tif` for each tile.

---

## 4. Results

Here is a complete **Markdown section** you can directly paste into your `README.md`. Replace the image paths with the actual filenames (e.g., `figures/chm_hillshade_2018.png`) once your screenshots are ready.

---

## 4. Visual Outputs & Interpretation

This section presents a set of raster visualizations exported from QGIS to interpret forest structural metrics and temporal changes across LiDAR datasets. All outputs are derived from the `process_chm_pipeline()` and `run()` differencing workflows. Hillshades are used for enhanced visual contrast and spatial comprehension.

---

### **4.1 Forest Metric Hillshades**

#### **Figure 1. Canopy Height Model (CHM) Hillshade — 2018**

![Figure 1](figures/chm_hillshade_2018.png)

*Hillshade of the CHM raster generated from normalized LiDAR point cloud returns. Brighter areas represent taller vegetation. This output was created using the `rasterize_canopy()` function with `dsmtin()` algorithm, followed by `terra::shade()`.*

---

#### **Figure 2. Digital Surface Model (DSM) Hillshade — 2018**

![Figure 2](figures/dsm_hillshade_2018.png)

*Surface elevation hillshade derived from the topmost LiDAR returns. Includes canopy tops and infrastructure. Generated using `rasterize_canopy()` on unnormalized data.*

---

#### **Figure 3. Digital Terrain Model (DTM) Hillshade — 2018**

![Figure 3](figures/dtm_hillshade_2018.png)

*Terrain-only hillshade, representing bare-earth elevation. Interpolated using the `tin()` method in `rasterize_terrain()`. Used as the base for CHM normalization.*

---

#### **Figure 4. Canopy Cover Hillshade — 2018**

![Figure 4](figures/canopy_cover_hillshade_2018.png)

*Grid showing canopy cover percentage from first-return points above 1 meter. Calculated as the ratio of points above 1m to total first returns, using `grid_metrics()`.*

---

#### **Figure 5. Density >2m Hillshade — 2018**

![Figure 5](figures/density_above_2m_hillshade_2018.png)

*Proportion of LiDAR returns greater than 2 meters height. Highlights spatial variability in mid-to-upper canopy density. Computed using `sum(Z > 2) / length(Z)`.*

---

### **4.2 CHM Differencing and VRT Mosaics**

#### **Figure 6. CHM Difference Raster (2012–2018)**

![Figure 6](figures/chm_difference_hillshade_2012_2018.png)

*Pixel-wise difference in canopy height between 2012 and 2018. Positive values (green) represent canopy growth, negative values (red) indicate loss — such as from logging or wildfire. Created using `compute_difference()` and visualized via QGIS hillshade overlay.*

---

#### **Figure 7. VRT Mosaic — CHM Differences (Diff VRT)**

![Figure 7](figures/chm_diff_vrt.png)

*Virtual mosaic built from all CHM difference rasters. Constructed using GDAL's `build_vrt()` in `run()` pipeline to support seamless analysis across tiles.*

---

#### **Figure 8. VRT Mosaic — CHM Original Tiles (2018)**

![Figure 8](figures/chm_vrt_2018.png)

*Tile-based VRT mosaic of original CHMs for 2018. Enables fast loading and visualization of large CHM datasets in QGIS or other raster tools.*

---

### Notes:

* All hillshades were generated with `terra::shade()` using slope and aspect from corresponding rasters.
* VRT mosaics are saved in the parent folder of each metric group for both original and differenced rasters.
* These outputs can be further analyzed in QGIS (e.g., for zonal stats, overlays) as the next step.

---

## 5. Why This Project Matters

* Enables quantitative monitoring of forest recovery after wildfires and other disturbances.
* Supports large‑scale, multi‑temporal studies by automating tedious point‑cloud processing.
* Delivers open‑source, reproducible workflows for the research community (OpenForest4D).

---

## 6. License & Citation

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

To cite this work, use the provided [CITATION.cff](CITATION.cff) or:

```bibtex
@software{OpenForest4D,
  title = {OpenForest4D LiDAR Processing Pipeline},
  author = {Your Name and collaborators},
  year = {2025},
  url = {https://github.com/YourUser/OpenForest4D}
}
```

---

## 7. References & Further Reading

* USGS 3DEP EPT service: [https://3dep.us](https://3dep.us)
* OpenTopography AWS S3 access: [https://opentopography.org](https://opentopography.org)
* PDAL documentation: [https://pdal.io](https://pdal.io)
* lidR R package: [https://cran.r‑project.org/package=lidR](https://cran.r‑project.org/package=lidR)
* UTM coordinate system overview: [https://epsg.io/32610](https://epsg.io/32610)

---

## 8. Contribution & Support

Issues and pull requests are welcome. Please see \[CONTRIBUTING.md] for guidelines or open an issue if questions arise.
