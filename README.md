# OpenForest4D LiDAR Processing Pipeline

This repository contains automated workflows for retrieving, processing, and analyzing multi‑temporal LiDAR data to detect forest structural change. The pipeline supports:

- **Data retrieval** from USGS EPT or OpenTopography S3  
- **Reprojection** and **tiling** of raw point clouds  
- **Extraction** of forest metrics (e.g., canopy height, rumple index)  
- **Differencing** of canopy height models (CHMs) over time  
- **Visualization** of change products via QGIS  

By standardizing each step in Jupyter notebooks and scripts, the project ensures reproducibility, scalability, and ease of adaptation for new areas or time periods. This work underpins the NSF‑funded OpenForest4D initiative, enabling researchers to quantify post‑disturbance recovery and long‑term forest dynamics.

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

````

---

## 2. Installation & Setup

Refer to **Setup Instructions** for full details (see below or [Data_Retrieval_Instructions.md]).

1. **Clone repo**  
   ```bash
   git clone https://github.com/YourUser/OpenForest4D.git
   cd OpenForest4D
````

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

* **CHM maps** (pre‑ and post‑disturbance)
* **Difference maps** showing gain (green) and loss (red)
* **QGIS maps** illustrating canopy height distribution changes


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
