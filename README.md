[![NSF-2409887](https://img.shields.io/badge/NSF-2409887-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=2409887) 
[![NSF-2409885](https://img.shields.io/badge/NSF-2409885-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=2409885)
[![NSF-2409886](https://img.shields.io/badge/NSF-2409886-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=2409886)

# OpenForest4D Multi-Temporal Lidar Processing Pipeline

**Authors**  
- **Sreeja Krishnamari** (Primary Author)  
- Chelsea Scott (Co-Author)

This repository contains workflows for retrieving, processing, and analyzing multi‑temporal lidar data to detect changes to tree canopies in forests. The pipeline supports:

- **Data retrieval** from the USGS 3D Elevation Project and OpenTopography
- **Reprojection** and **tiling** of lidar point cloud data  
- **Calculation** of grid/raster-based forest metrics using lidR (e.g., canopy height model, rumple index)  
- **Differencing** of DSM's, DTM's, canopy height models, canopy cover and rumple over time
- **Visualization** of topographic hillshades and change products via QGIS  

By standardizing each step in Jupyter notebooks and R scripts, this workflow ensures reproducibility, scalability, and ease of adaptation for applying these calculations to new areas with modern and legacy lidar datasets. This work is supported by the NSF‑funded OpenForest4D project and was conducted at Arizona State University. 

![Figure 1](figures/AGU.png)

**Example Output: Canopy Height Change Analysis on the Kaibab National Forest, northern Arizona (2012–2019)**

The figure above illustrates canopy height model change along the Kaibab National Forest in northern Arizona, derived using our multi-temporal lidar processing pipeline. Airborne lidar data from 2012 and 2019 were processed using this  pipeline.

* **Main Map (left):** Displays canopy height model change between 2012 and 2019.
* 
  * **Blue areas** indicate gain in canopy height.
  * **Whites areas** indicate no change in canopy height.
  * **Red areas** indicate loss in canopy height.
 
* **Insets (right):**

  * **Top:** CHM from 2012.
  * **Middle:** CHM from 2019.
  * **Bottom:** Differenced CHM (2019 − 2012).
* **Green Polygons:** Represent wildfire perimeters during the analysis period from Monitoring Trends in Burn Severity (https://mtbs.gov).

This figure demonstrates the output of the full processing pipeline, from raw point cloud tiling and classification to raster generation, coordinate system projection, differencing, and final visualization for ecological change analysis.


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

### Option 1: Data Retrieval (if point cloud LAZ/LAS files not already available)

* **Primary method:**
  Run `notebooks/intersection_data_retriever.ipynb` (USGS 3DEP- In Entwine Point Tiles (EPT) format (https://entwine.io from Amazon Web Services (AWS) Simple Storage Service (S3) Public Dataset bucket (https://registry.opendata.aws/usgs-lidar/).
* **Alternative S3:**
  Check `Data_Retrieval_Instructions.md` steps for AWS S3.

### Option 2: Tiling

If point clouds are not yet tiled (likely to be the case):

1. **Script:**

   ```bash
    lastile -i C:\Users\sreeja\Documents\OpenForest4D\Data\*.laz ^
        -tile_size 1000 ^
        -buffer 20 ^
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

### Step 2:  Differencing of the Canopy Height Model and other raster products

*  Compute pixel‑wise change between two two lidar acquisitions to detect change to the forest canopy.
* **Notebook:**
  `notebooks/differencing_script.ipynb` loads rasters representing lidar data from different acqusitions from two folders, calculates difference, and exports the difference as GeoTIFF files.
* **Output:** (CHM) `CHM_Difference.tif` for each tile.



## 4. Visual Outputs & Interpretation

This section presents a set of raster visualizations exported from QGIS to interpret forest metrics and temporal changes across multi-temporal lidar datasets. All outputs are derived from running the scripts in order. Shaded relief maps/ hillshades are used for enhanced visual contrast and spatial comprehension.


### **4.1 Forest Metric Visualizations**

Figures 1, 2, 3, 4, and 5 represent the metrics calculated for the Kaibab National Forest of Northern Arizona using lidar collected in 2019.



![Figure 1](figures/chm_hillshade.png)

#### Figure 1. Canopy Height Model Hillshade (CHM) 
*Hillshade/ shaded relief map of the normalized digital surface model generated from lidar data collected in 2019.*

Data citation: U.S. Geological Survey (2020). AZ NorthKaibabNF B1 2019. Distributed by OpenTopography. https://portal.opentopography.org/usgsDataset?dsid=AZ_NorthKaibabNF_B1_2019. Accessed: 2025-05-13.

![Figure 2](figures/CHM.png)
#### Figure 2. Canopy Height Model (CHM) 

![Figure 3](figures/dsm_hillshade.png)
#### Figure 3. Digital Surface Model (DSM) Hillshade
*This map shows vegetation height above ground level across the Kaibab National Forest, derived using the normalized point cloud method. Lidar returns were first normalized by subtracting the Digital Terrain Model (DTM) from the raw point elevations, setting ground height to zero. The resulting CHM depicts the tallest canopy returns per grid cell, with heights ranging from 0 m (yellow) to over 20 m (dark green).*
Data citation: U.S. Geological Survey (2020).

![Figure 4](figures/dtm_hillshade.png)
#### Figure 4. Digital Terrain Model (DTM) Hillshade

*Bare-earth topographic hillshade, interpolated using the triangulated irregular network (tin) method. Used as the base for point cloud normalization.*

Data citation: U.S. Geological Survey (2020).


![Figure 5](figures/canopy_cover.png)
#### Figure 5. Canopy Cover Hillshade

*Image showing canopy cover percentage of first-return points above 1 meter calculated at 10 meter resolution. Calculated as the ratio of points above 1m relative to the total first returns.*

Data citation: U.S. Geological Survey (2020).


![Figure 6](figures/density.png)
#### Figure 6. Density >2m Hillshade — 2018

*Proportion of all lidar returns greater than 2 meters height calculated at 10 meter resolution. Highlights spatial variability in mid-to-upper canopy density.*

Data citation: U.S. Geological Survey (2020).


### 4.2 Differencing and VRT Visualizations

The below image represents the pixel-wise difference in canopy height between the years 2019 and 2021 of the Castle fires in the Kaibab Plateau of Northern Arizona. These plots are made using the differencing_script.ipynb notebook and visualized in QGIS.


![Figure 7](figures/chm_diff.png)
#### Figure 7. CHM Difference Raster

*Positive values (green) represent canopy growth, values of zero (white) indicate no change, and negative values (red) indicate loss due to the wildfire.*

Data citation: U.S. Geological Survey (2020). OpenTopography (2012): Mapping the Kaibab Plateau, AZ. Distributed by OpenTopography, 2012, https://doi.org/10.5069/G9TX3CH3 . 

![Figure 8](figures/dsm_diff.png)
#### Figure 8: DSM Difference Raster

*Positive values (green) represent increased surface elevation, often due to vegetation recovery or debris accumulation. Zero (white) indicates no change, while negative values (red) suggest loss of surface features like canopy due to wildfire damage in this case.*
Data citation: U.S. Geological Survey (2020), OpenTopography (2012)


![Figure 9](figures/dtm_diff.png)
#### Figure 9: DTM Difference Raster

*Positive values (green) represent elevation gain in the bare-earth surface, potentially due to sediment deposition or ground movement. Zero (white) indicates stability, and negative values (red) reflect erosion or surface material loss, such as landslides.*
Data citation: U.S. Geological Survey (2020), OpenTopography (2012)


![Figure 10](figures/rumple_diff.png)
#### Figure 10: Rumple Index Difference Raster

*Positive values (green) indicate increased surface roughness and structural complexity, suggesting heterogeneous regrowth or debris presence. Zero (white) shows no change, while negative values (red) represent smoother surfaces caused by canopy or structure loss after wildfire.*
Data citation: U.S. Geological Survey (2020), OpenTopography (2012)


![Figure 11](figures/canopy_cover_diff.png)
#### Figure 11: Canopy Cover Difference Raster
*Positive values (green) represent increased canopy cover, indicating vegetation regrowth. Zero (white) indicates no change, while negative values (red) show a reduction in canopy density.*
Data citation: U.S. Geological Survey (2020), OpenTopography (2012)


![Figure 12](figures/density_diff.png)
#### Figure 12: Density >2m Difference Raster

*Positive values (green) reflect an increase in lidar returns above 2 meters, suggesting canopy recovery. Zero (white) indicates unchanged vertical structure, and negative values (red) reflect thinning or removal of tall vegetation due to wildfire.*
Data citation: U.S. Geological Survey (2020), OpenTopography (2012)


### Notes:

* VRT mosaics are saved in the parent folder of each metric group for both original and differenced rasters.
* These outputs can be further analyzed in QGIS.


## 5. Why This Project Matters

* Supports large‑scale, multi‑temporal analysis by automating point‑cloud processing.
* Delivers open‑source, reproducible workflows for the research community (OpenForest4D).
* Enables quantitative monitoring of forest changes following wildfires and other disturbances.


## 6. License & Citation

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

To cite this work, use the provided [CITATION.cff](CITATION.cff) or:

```bibtex
@software{OpenForest4D,
  title = {OpenForest4D lidar Processing Pipeline},
  author = {Sreeja Krishnamari and Chelsea Scott},
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
