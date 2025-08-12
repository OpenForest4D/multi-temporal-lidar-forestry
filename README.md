# OpenForest4D lidar Processing Pipeline

This repository contains workflows for retrieving, processing, and analyzing multi‑temporal lidar data to detect structural changes to forests. The pipeline supports:

- **Data retrieval** from USGS EPT and OpenTopography S3  
- **Reprojection** and **tiling** of point clouds  
- **Extraction** of raster-based forest metrics (e.g., canopy height model, rumple index)  
- **Differencing** of DSM's, DTM's, canopy height models, canopy cover and rumple over time
- **Visualization** of topographic hillshades and change products via QGIS  

By standardizing each step in Jupyter notebooks and R scripts, the project ensures reproducibility, scalability, and ease of adaptation for new areas or time periods. This work is supported by the NSF‑funded OpenForest4D project.

![Figure 1](figures/AGU.png)

**Example Output: Canopy Height Change Analysis on the Kaibab Plateau (2012–2019)**

The figure above illustrates forest structure change on the Kaibab Plateau in northern Arizona, derived using the multi-temporal lidar processing pipeline. Airborne lidar data from 2012 and 2019 were processed using this  pipeline.

* **Main Map (left):** Displays CHM height change between 2012 and 2019.

  * **Red areas** indicate loss in canopy height.
  * **Blue areas** indicate gain in canopy height.
* **Insets (right):**

  * **Top:** CHM from 2012.
  * **Middle:** CHM from 2019.
  * **Bottom:** Differenced CHM (2019 − 2012).
* **Green Polygons:** Represent wildfire perimeters during the analysis period.

This figure demonstrates the output of the full processing pipeline, from raw point cloud tiling and classification to raster generation, spatial alignment, differencing, and final visualization for ecological change analysis.


---

## 1. Repository Structure

```

project-root/
data/
  usgs_3dep_boundaries.geojson

notebooks/
  intersection_data_retriever.ipynb
  tiling.ipynb
  differencing_script.
  tiling.ipynb

R/
  forestry_metrics.R
  classify_ground.R

instructions/
  Data_Retrieval_Instructions.md
  R_metrics.md
  Setup_Instructions.md

environment.yml
README.md
LICENSE
CITATION.cff


```


## 2. Installation & Setup

Refer to Setup Instructions for full details (see below or [Data_Retrieval_Instructions.md]).


## 3. Workflow & How to Run

### Option 1: Data Retrieval (if raw LAZ not already available)

* **Primary method:**
  Run `notebooks/intersection_data_retriever.ipynb` (USGS EPT).
* **Alternative S3:**
  Check `Data_Retrieval_Instructions.md` steps for AWS S3.

### Option 2: Tiling

If point clouds exist but tiling is needed:

1. **Script:**

   ```bash
    lastile -i C:\Users\sreeja\Documents\OpenForest4D\Data\*.laz ^
        -tile_size 1000 ^
        -buffer 10 ^
        -odir C:\Users\sreeja\Documents\OpenForest4D\2012_tiled ^
        -olaz ^
        -cores 4
   ```
2. **Notebook fallback:**
   Open `notebooks/tiling.ipynb`, set `input_dir`, `output_dir`, `tile_size`, `buffer`, `cores`, then run the "Tiling LAZ files" cell.

### Step 1: Extract Forest Metrics

*  Derive canopy height, canopy cover, rumple index, and point density metrics for each tile.
* **Script:**
  Open `notebooks/forestry_metrics.R` in RStudio and run end‑to‑end.
* **Output:** GeoTIFF rasters (e.g., `CHM.tif`, `Rumple.tif`) saved under the same tile folder.

### Step 2: CHM Differencing

*  Compute pixel‑wise change between two dates to detect growth or disturbance.
* **Notebook:**
  `notebooks/differencing_script.ipynb` loads CHM rasters from two folders, calculates difference, and exports  difference GeoTIFFs.
* **Output:** `CHM_Difference.tif` for each tile.



## 4. Visual Outputs & Interpretation

This section presents a set of raster visualizations exported from QGIS to interpret forest structural metrics and temporal changes across lidar datasets. All outputs are derived from running the scripts in order. Hillshades are used for enhanced visual contrast and spatial comprehension.


### **4.1 Forest Metric Visualizations**

Figure 1, 2, 3, 4, 5 represent the metrics calculated for the Kaibab National Forest of Northern Arizona using lidar collected in 2019.

#### Figure 1. Canopy Height Model (CHM) 

![Figure 1](figures/chm_hillshade.png)

*Hillshade of the normalized digital surface model generated from lidar point cloud returns.*

U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.

![Figure 2](figures/CHM.png)

U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.


#### Figure 2. Digital Surface Model (DSM) Hillshade

![Figure 2](figures/dsm_hillshade.png)

*Surface elevation hillshade derived from the topmost lidar returns.*

U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.


#### Figure 3. Digital Terrain Model (DTM) Hillshade

![Figure 3](figures/dtm_hillshade.png)

*Terrain-only hillshade, representing bare-earth elevation. Interpolated using the tin() method. Used as the base for CHM normalization.*

U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.


#### Figure 4. Canopy Cover Hillshade

![Figure 4](figures/canopy_cover.png)

*Image showing canopy cover percentage from first-return points above 1 meter. Calculated as the ratio of points above 1m to total first returns.*

U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.


#### Figure 5. Density >2m Hillshade — 2018

![Figure 5](figures/density.png)

*Proportion of lidar returns greater than 2 meters height. Highlights spatial variability in mid-to-upper canopy density.*

U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.


### 4.2 Differencing and VRT Visualizations

The below image represents the pixel-wise difference in canopy height between the years 2019 and 2021 of the Castle fires in the Kaibab Plateau of Northern Arizona. They are made using the differencing_script.ipynb notebook and visualized in QGIS.

#### Figure 6. CHM Difference Raster

![Figure 6](figures/chm_diff.png)

*Positive values (blue) represent canopy growth, negative values (red) indicate loss due to the wildfire.*

U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.

### Notes:

* VRT mosaics are saved in the parent folder of each metric group for both original and differenced rasters.
* These outputs can be further analyzed in QGIS as the next step.


## 5. Why This Project Matters

* Enables quantitative monitoring of forest recovery after wildfires and other disturbances.
* Supports large‑scale, multi‑temporal studies by automating tedious point‑cloud processing.
* Delivers open‑source, reproducible workflows for the research community (OpenForest4D).


## 6. License & Citation

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

To cite this work, use the provided [CITATION.cff](CITATION.cff) or:

```bibtex
@software{OpenForest4D,
  title = {OpenForest4D lidar Processing Pipeline},
  author = {Your Name and collaborators},
  year = {2025},
  url = {https://github.com/YourUser/OpenForest4D}
}
```


## 7. References & Further Reading

* USGS 3DEP EPT service: [https://3dep.us](https://3dep.us)
* OpenTopography AWS S3 access: [https://opentopography.org](https://opentopography.org)
* PDAL documentation: [https://pdal.io](https://pdal.io)
* lidR R package: [https://cran.r‑project.org/package=lidR](https://cran.r‑project.org/package=lidR)
* UTM coordinate system overview: [https://epsg.io/32610](https://epsg.io/32610)

---
