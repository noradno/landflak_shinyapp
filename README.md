# Country Snapshot App

This Shiny app provides statistical country snapshots of Norwegian development aid (ODA) to developing countries. Users can select a recipient country from a dropdown menu, and a parametrized Quarto report is dynamically rendered as .docx and downloaded directly in the browser. Each report provides a summary of Norwegian aid to the selected country, based on the most recent available data from APIs, databases, and manually updated files.

👉 Access the app at: [https://noradstats.shinyapps.io/](https://noradstats.shinyapps.io/country-snapshot){.uri}[landflak](https://noradstats.shinyapps.io/landflak/)

## 🔄 Data Pipeline Overview

A dedicated data pipeline retrieves, processes, and transforms data from multiple sources, producing the cleaned `.rds` files that power the app. The entry point to the pipeline is the function `run_pipeline()`.

> ⚠️ **Before running the pipeline:** The `data/raw/` folder contains CSV files that must be manually updated. This includes:
>
> -   `imputed_multi_land_org.csv` (a main data source): A manually maintained dataset of Norwegian imputed multilateral aid, by organization and country.
> -   `crs_donors_code.csv`, `crs_recipients_code.csv`, `exchangerate.csv`, and `land_og_regioner.csv` (helper files)
>
> For a complete guide to updating these files, see the section [📅 Manually Updating Input CSV Files](#📅-manually-updating-input-csv-files).

### How to Run

``` r
# Optional: load required packages first
renv::restore()

# Run the pipeline to prepare data for the app
source("scripts/pipeline/run_pipeline.R")
run_pipeline(last_year_donors = 2023, last_year_imputed = 2023, version = "statsys_official")
```

### Main Steps: executed by `run_pipeline()`

-   `get_data_donors(last_year)`: Fetches bilateral donor data for the specified year from the **OECD SDMX API**.
-   `get_data_imputed(last_year)`: Fetches Norwegian imputed multilateral data for the last 10 years ending in the specified year from the **OECD SDMX API**.
-   `get_data_bilateral(version)`: Extracts bilateral aid from **Norad's statsys database** (DuckDB) for the most recent 10 years.
-   `get_data_imputed_org()`: Reads manually imputed multilateral aid by organization (one year only) from a **CSV file**.
-   `create_final_data(df_dac_raw, df_imputed_raw, df_oda_ten, df_imp_org_raw)`: Final assembly step that merges, filters, and writes cleaned data files to `data/final/`.

The pipeline saves the following `.rds` datasets to the `data/final/` folder:

-   `df_oda_ten.rds`
-   `df_dac_raw.rds`
-   `df_imp_raw.rds`
-   `df_imp_org_raw.rds`
-   `df_countries.rds`

All of these are consumed directly by the Shiny app.

### 🔁 Update Frequency

The app should be updated whenever any of the underlying data sources are updated. In particular, the bilateral aid data retrieved by `get_data_bilateral()` should reflect the official data published at [aidresults.no](https://www.aidresults.no).

## 🗂️ Project Structure

```         
├── app.R                          # Main Shiny app launcher
├── country_snapshot.qmd           # Parametrized Quarto report for selected country
├── country_snapshot_output.docx   # Example output (optional)
├── scripts/
│   ├── helpers/                   # Functions used by Quarto report (plots, tables, formatting)
│   ├── pipeline/                  # Data processing scripts: get_data_*(), create_final_data(), run_pipeline()
│   └── setup/                     # Project-level setup scripts (e.g. load_packages.R)
├── data/
│   ├── raw/                       # Manually maintained input CSVs
│   └── final/                     # Cleaned .rds files used by app and report
├── template/                      # Word reference-docx for Norad styling
├── www/                           # Static assets (e.g. Norad logo for login page)
├── config.yml                     # Login credentials (gitignored)
├── ui_text.md                     # Markdown content for app UI
├── rsconnect/                     # Deployment metadata (auto-generated)
├── renv/, renv.lock               # Dependency management
├── README.md                      # This file
└── landflak_shinyapp.Rproj        # RStudio project file
```

## ⚙️ Setup Instructions

``` r
# Restore project dependencies
renv::restore()

# Run the pipeline to prepare data for the app
source("scripts/pipeline/run_pipeline.R")
run_pipeline(last_year_donors = 2023, last_year_imputed = 2023, version = "statsys_official")
```

## 👤 Maintainer

Developed and maintained by the Section for Statistics and Analysis, Norad.

## ☁️ Deployment

The app is published to [shinyapps.io](https://www.shinyapps.io) using the [`rsconnect`](https://rstudio.github.io/rsconnect/) package from **RStudio**. When ready, you can publish the app by clicking **"Publish"** in the RStudio IDE or using the deployment wizard.

Deployment metadata is stored in the `rsconnect/` folder.

👉 Live app: <https://noradstats.shinyapps.io/country-snapshot>

## 🛠️ Troubleshooting Deployment

-   **Deployment fails with an error**: Check the app logs at [shinyapps.io](https://www.shinyapps.io). This is often caused by outdated packages. Make sure to update packages—especially `noradstats` and `noradplot`—then run `renv::snapshot()` before re-deploying.

-   **Deployment succeeds but report doesn't render correctly (e.g. renders `report.html`)**: This is typically due to a missing Word template. Ensure the file in `template/` is included when deploying. App logs at shinyapps.io may provide further clues.

## 📅 Manually Updating Input CSV Files

The following files in the `data/raw/` folder must be manually maintained and updated before running the pipeline:

-   **`land_og_regioner.csv`**: Lookup table with friendly country names used for display (e.g. on [bistandsresultater.no](https://www.bistandsresultater.no)). Source: `land_og_regioner.xlsx` from the latest data load to bistandsresultater.no. Enables link creation to country pages.

-   **`exchangerate.csv`**: Contains fixed USD-to-NOK exchange rates published by OECD annually in April. Source: [OECD Exchange Rates Excel file](https://www.oecd.org/dac/financing-sustainable-development/development-finance-data/Exchange-rates.xls). These rates are preferred over the default API rates.

-   **`crs_donors_code.csv`**: Two-column file mapping `crs_donors_code` to `iso_code`. Required for querying OECD APIs in `get_data_donors()` and `get_data_imputed()`. Source: [OECD CRS/DAC Code Lists](https://web-archive.oecd.org/temp/2024-06-19/57753-dacandcrscodelists.htm)

-   **`crs_recipients_code.csv`**: Similar structure as above, mapping `crs_recipients_code` to `iso_code`. Also used in OECD queries. Source: [OECD CRS/DAC Code Lists](https://web-archive.oecd.org/temp/2024-06-19/57753-dacandcrscodelists.htm)

-   **`imputed_multi_land_org.csv`** (**main data source**): A manually maintained dataset of Norwegian imputed multilateral aid, by organization and country. Must reflect the latest available year.

Be sure to keep these files up to date and aligned with the latest official data before executing `run_pipeline()`.
