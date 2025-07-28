# Setup Instructions

These instructions are a guide for installing all necessary software, creating environments, and running the provided Jupyter and R scripts. 


---

## 1. Installing Python and Conda

Python 3.8 or higher is required. The Conda package manager provides isolated environments and consistent dependency resolution.

1. **Download the Anaconda distribution**  
   - Official Anaconda installer (includes conda plus ~200 packages):  
     https://www.anaconda.com/products/distribution  
   - Choose the appropriate installer for Windows, macOS, or Linux.  
   - Follow on‑screen prompts to complete installation.

2. **(Optional) Install Miniconda for a lightweight setup**  
   - Miniconda contains only conda and its core dependencies (~50 MB).  
   - Subsequent packages are installed on demand, reducing disk usage and update time.  
   - Official Miniconda page:  
     https://docs.conda.io/en/latest/miniconda.html  
   - Use the same `conda` commands and channels (for example, `conda-forge`) as the full distribution.

3. **Open a Conda-enabled prompt**  
   - **Windows**: launch **Anaconda Prompt** (or **Miniconda Prompt**) from the Start menu  
   - **macOS / Linux**: open the default Terminal application  

4. **Verify installation**  
   ```bash
   conda --version
   ```


## 2. Cloning the Repository and Environment File

The repository contains an `environment.yml` manifest listing all Python and R dependencies.

1. Clone the GitHub repository:  
   ```bash
   git clone https://github.com/YourUser/YourRepo.git
   cd YourRepo
  ```

2. Inspect `environment.yml` to review listed packages.

---

## 4. Creating the Conda Environment

Creating a dedicated environment prevents conflicts with other Python projects.

1. Create and activate the environment named **lidar\_env**:

   ```bash
   conda env create -f environment.yml
   conda activate lidar_env
   ```

2. Verify installation:

   ```bash
   conda list
   ```

   * Confirms that packages such as **geopandas**, **shapely**, **pyproj**, **pdal**, and **jupyterlab** are present.

---

## 5. Installing Additional Python Packages

If `environment.yml` is modified or missing certain tools, install via Conda:

```bash
conda install -c conda-forge pdal python-pdal
conda install -c conda-forge geopandas shapely pyproj
```

These packages provide:

* **pdal / python-pdal**: Lidar point‑cloud I/O and processing
* **geopandas**, **shapely**, **pyproj**: vector geometry and coordinate transformations

---

## 6. Launching JupyterLab

JupyterLab offers an interactive interface for notebooks.

1. In the activated environment, start JupyterLab:

   ```bash
   jupyter lab
   ```
2. In the browser window, navigate to the `notebooks/` folder and open the desired `.ipynb` file.

---

## 7. Using Google Colab (Optional)

For cloud execution without local setup:

1. Open Colab:
   [https://colab.research.google.com](https://colab.research.google.com)
2. Select **GitHub** and paste the repository URL.
3. Run cells directly in the browser.
4. Install missing dependencies in a cell, for example:

   ```bash
   !pip install geopandas shapely pyproj pdal
   ```

---

## 8. Installing R and RStudio

R scripts require R 4.0+ and RStudio for interactive editing.

1. Install R from CRAN:
   [https://cran.r-project.org](https://cran.r-project.org)
2. Install RStudio Desktop:
   [https://www.rstudio.com/products/rstudio/download](https://www.rstudio.com/products/rstudio/download)
3. Launch RStudio and install required packages in the **Console** pane:

   ```r
   install.packages(c("terra", "future"))
   # For lidR:
   install.packages("lidR")
   ```

---

## 9. Running R Scripts

1. In RStudio, open `notebooks/forestry_metrics.R`.
2. Ensure the working directory matches the repository root (Session -> Set Working Directory).
3. Run the script (Source button or `Ctrl+Shift+Enter`).

---

## 10. Verifying the Setup

1. Run a small example in JupyterLab:

   * Open `notebooks/intersection_data_retriever.ipynb`.
   * Edit only the first cell to point at a small test boundary GeoJSON.
   * Execute the first cell and confirm no import errors.

2. In RStudio, run the first few lines of `forestry_metrics.R` to confirm packages load without errors.

---

## 11. Troubleshooting Tips

* “Command not found”: confirm that the Conda environment is active (`conda activate lidar_env`).
* “Module not found”: install missing Python packages via Conda or pip.
* “PDAL library error”: ensure system‑level PDAL is installed (see [https://pdal.io](https://pdal.io)).
* R package failures: run `install.packages()` again and verify internet access.

---

With this setup, all notebooks and scripts will run in a consistent environment. Adjust paths in the first cell of each notebook to match local directories as needed.
