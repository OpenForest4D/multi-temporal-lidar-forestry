[![NSF-2409887](https://img.shields.io/badge/NSF-2409887-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=2409887) 
[![NSF-2409885](https://img.shields.io/badge/NSF-2409885-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=2409885)
[![NSF-2409886](https://img.shields.io/badge/NSF-2409886-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=2409886)

# Multi-Temporal Lidar Workflow for Forest Change Mapping

This repository contains reproducible workflows for retrieving, processing, and analyzing multi-temporal lidar data to detect changes in forest canopies, with example applications in wildfire-affected forests. This project is supported by NSF funded OpenForest4D project and developed at Arizona State University.
- Authors:  Sreeja Krishnamari (Primary Author), Chelsea Scott (Co-Author)

The workflow supports:

- Data retrieval from the USGS 3D Elevation Project and OpenTopography
- Lidar point cloud reprojection and tiling  
- Grid/raster-based forest metrics calculation (e.g., canopy height model, rumple index)  
- Temporal differencing of DSM's, DTM's, canopy height models, canopy cover and rumple over time
- Topographic hillshades and change visualizations via QGIS  

Standardizing each step in Jupyter notebooks and R scripts makes the workflow reproducible, scalable, and easily adaptable for applying these calculations to new regions using both modern and legacy lidar datasets.

![Figure 1](figures/AGU.png)

**Example Output: Canopy Height Change Analysis on the Kaibab National Forest, northern Arizona (2012-2019)**

The figure above shows changes in the canopy height model along the Kaibab National Forest in northern Arizona, generated with our multi-temporal lidar processing workflow. The workflow was applied to airborne lidar data collected in 2012 and 2019.

* **Main Map (left):** Displays canopy height model change between 2012 and 2019.
 
  * **Blue areas** indicate gain in canopy height.
  * **Whites areas** indicate no change in canopy height.
  * **Red areas** indicate loss in canopy height.
 
* **Insets (right):**

  * **Top:** CHM from 2012.
  * **Middle:** CHM from 2019.
  * **Bottom:** Differenced CHM (2019 - 2012).
* **Green Polygons:** Represent wildfire perimeters during the analysis period from Monitoring Trends in Burn Severity (https://mtbs.gov).

This figure illustrates the complete processing workflow, starting with raw point cloud tiling and classification, followed by raster generation, projection to a common coordinate system, differencing, and culminating in the final visualization used for ecological change analysis.

## 1. Repository Structure

```
project-root/
  data/
    usgs_3dep_boundaries.geojson

  notebooks/
    intersection_data_retriever.ipynb
    tiling.ipynb
    differencing_script.ipynb

  R/
    forestry_metrics.R
    classify_ground.R

  instructions/
    Setup_Instructions.md
    Data_Retrieval_Instructions.md
    R_metrics.md

  environment.yml
  LICENSE
  CITATION.cff
  README.md
```

## 2. Installation & Quick Start

Refer to [instructions/Setup_Instructions.md](instructions/Setup_Instructions.md) for platform-specific setup steps.

## 3. Workflow Summary

### Step 1: Data Retrieval

* **Primary method:**
  Run `notebooks/intersection_data_retriever.ipynb` - This notebook automates the retrieval of lidar point-cloud data for a specified region of interest by leveraging the USGS 3DEP Entwine Point Tile (EPT) service. (https://registry.opendata.aws/usgs-lidar/)
  
* **Alternative S3:**
  Follow steps in `instructions/Data_Retrieval_Instructions.md` for obtaining lidar point cloud data from both the OpenTopography bulk download AWS S3 buckets and the USGS EPT (Entwine Point Tile) service, reprojecting the data into a consistent coordinate system, and tiling the data into manageable tiles.

### Step 2: Tiling (Optional):

If point clouds are not yet tiled (likely to be the case):

1. **Script:**

   ```bash
    lastile -i /data/*.laz ^
        -tile_size 1000 ^
        -buffer 20 ^
        -odir /data/2012_tiled ^
        -olaz ^
        -cores 4
   ```
2. **Notebook fallback:**

    Run `notebooks/tiling.ipynb` to tile LAZ/LAS files after setting `input_dir`, `output_dir`, `tile_size`, `buffer`, `cores`.

### Step 3: Forest Metrics Extraction

*  Derive canopy height, canopy cover, rumple index, and point density metrics for each tile.
* **Script:** Run `notebooks/forestry_metrics.R` calculate canopy height, rumple index, cover, etc. 
* **Output:** GeoTIFF rasters (e.g., `CHM.tif`, `Rumple.tif`) saved under the same tile folder.

### Step 4:  Differencing of the Canopy Height Model and other raster products

*  Compute pixel-wise change between two two lidar acquisitions to detect change to the forest canopy.
* **Notebook:** Use  `notebooks/differencing_script.ipynb` to compare and export difference rasters (e.g., Canopy Height Change).
* **Output:** (CHM) `CHM_Difference.tif` for each tile.  

## 4. Visualization Outputs & Interpretation

This section shows raster visualizations exported from QGIS that illustrate forest metrics and temporal changes from multi-temporal lidar datasets. All outputs are generated sequentially by running the provided scripts. Shaded relief maps (hillshades) are included to improve visual contrast and spatial interpretation.

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

## 5. Statement of Need

* Supports large-scale, multi-temporal analysis by automating point-cloud processing.
* Delivers open-source, reproducible workflows for the research community.
* Enables quantitative monitoring of forest changes following wildfires and other disturbances.

## 6. License & Citation

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

To cite this work, use the provided [CITATION.cff](CITATION.cff) or:

```bibtex
@software{multi-temporal-lidar-forestry,
  author = {Krishnamari, Sreeja and Scott, Chelsea},
  title = {{Multi-Temporal Lidar Workflow for Forest Change Mapping}},
  year = {2025},
  url = {https://github.com/OpenForest4D/multi-temporal-lidar-forestry},
  note = {GitHub repository}
}

```

## 7. References & Further Reading

* USGS 3DEP EPT service: [https://registry.opendata.aws/usgs-lidar/](https://registry.opendata.aws/usgs-lidar/)
* OpenTopography: [www.opentopography.org](https://opentopography.org)
* PDAL documentation: [pdal.io](https://pdal.io)
* lidR R package: [cran.r-project.org/web/packages/lidR/](https://cran.r-project.org/web/packages/lidR/index.html)
* UTM coordinate system overview: [epsg.io/32610](https://epsg.io/32610)
