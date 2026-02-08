# Replication Materials for: Digital Sports Participation and Academic Performance

## Overview
This repository contains the replication materials (code and documentation) for the study: **"Digital Sports Participation and Academic Performance: Unveiling the Non-linear Dynamics and Cognitive Compensation Across Institutional Contexts"**.

The project employs a hybrid workflow to handle the large-scale PISA 2018 dataset:
1.  **Python**: Used for efficient data cleaning, imputation, and merging.
2.  **Stata**: Used for Hierarchical Linear Modeling (HLM), robustness checks, and visualization.

## Data Access
The study utilizes the publicly available **PISA 2018** database. Due to copyright and size constraints, raw data is not hosted here.
* **Source:** [OECD PISA 2018 Database](https://www.oecd.org/en/data/datasets/pisa-2018-database.html)
* **Required Files:** Student Questionnaire (STU) and School Questionnaire (SCH) for China Hong Kong (HKG) and Nordic countries (FIN, DNK, SWE, NOR).

## File Structure & Usage Order

Please run the scripts in the following numerical order to ensure reproducibility.

### Step 1: Data Cleaning (Python)
* **File:** `01_Data_Cleaning_Python.py`
* **Description:** * Reads raw SAS7BDAT files.
    * Performs data cleaning, renaming, and missing value imputation (MICE).
    * Standardizes variables (Z-scores) and merges student/school data.
    * **Output:** Generates `PISA2018_HKG_FULL_v4.csv` and `PISA2018_Nordic_FULL_v4.csv`.
* **Requirements:** Python 3.x, `pandas`, `numpy`, `sklearn`.

### Step 2: Main Analysis (Stata)
* **File:** `02_Analysis_Main_Effects.do`
* **Description:** * Runs Hierarchical Linear Models (HLM) for Math, Reading, and Science.
    * Tests both Linear and Quadratic (U-shaped) effects.
    * Analyzes moderation effects of ICT Autonomy and Interest.
* **Output:** `Table_1_Main_Effects.rtf`, `Table_2_Moderation_Effects.rtf`.

### Step 3: Robustness Checks (Stata)
* **File:** `03_Analysis_Robustness_Checks.do`
* **Description:** * **Check 1:** Quintile Regression (Dummy variable approach) to verify non-linear trends without assuming a quadratic function.
    * **Check 2:** Trimmed Sample Analysis (excluding outliers |Z|>2.5) to ensure results are not driven by extreme values.
* **Output:** `Table_Robustness.rtf`.

### Step 4: Visualization (Stata)
* **File:** `04_Figure_Plotting.do`
* **Description:** * Generates the 4-panel composite figure (Figure 1) showing the non-linear associations across all subjects.
* **Output:** `Figure1_Combined_4_Panels.png`.

### Step 5: Final Tables & Descriptive Statistics (Stata)
* **File:** `05_Final_Analysis_and_Tables.do`
* **Description:** * An all-in-one script that runs the full control models and exports all final tables used in the manuscript (including Descriptive Statistics).
* **Output:** `Table1_Descriptive_Statistics.rtf`, `Table_Threshold_Main.rtf`.

## Variable Mapping (Codebook)
Key variables were renamed for clarity during the Python processing stage:

| Concept | Raw PISA Variable | Renamed Variable |
| :--- | :--- | :--- |
| **Digital Sports** | `IC151Q07HA` | `DIGISPORT` |
| **Gender** | `ST004D01T` | `GENDER` |
| **SES** | `ESCS` | `ESCS` |
| **PE Classes** | `ST100Q01TA` | `PE_CLASSES` |
| **Teacher ICT Training** | `SC155Q08HA` | `T_TRAINING` |
| **Social ICT Perception** | `SOIAICT` | `SOIAICT` |

## Software Requirements
* **Stata:** Version 16.0 or later (Required for `mixed` and `marginsplot`).
* **Python:** Version 3.8+ (Required packages: `pandas`, `sklearn`).