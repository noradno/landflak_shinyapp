# Run the full data pipeline to produce cleaned and joined datasets of international and Norwegian ODA to recipient countries ----
#
# Required packages must be loaded before calling this function.
# This function assumes all supporting `get_data_*()` and `create_final_data()` functions are located in:
# scripts/pipeline/

#' Run the full data processing pipeline
#'
#' This function runs the full data processing pipeline:
#' 1. Downloads raw DAC donor and imputed multilateral data from OECD using the SDMX API
#' 2. Loads bilateral aid data from Norad's internal statsys database (last 10 years)
#' 3. Loads manually imputed multilateral disbursements by organization (latest year)
#' 4. Cleans and joins data, filters valid countries, and writes final `.rds` outputs
#'
#' @param last_year_donors Year to fetch DAC donor data for (default: 2023)
#' @param last_year_imputed Last year in 10-year range to fetch imputed multilateral data (default: 2023)
#' @param version Statsys version, either "statsys_official" (default) of "statsys_active"
#'
#' @examples
#' run_pipeline(last_year_donors = 2023, last_year_imputed = 2023)
#'
#' @export
run_pipeline <- function(last_year_donors = 2023, last_year_imputed = 2023, version = "statsys_official") {

  message("📦 Loading data pipeline functions from R scripts")
  source("scripts/pipeline/get_data_donors.R")
  source("scripts/pipeline/get_data_imputed.R")
  source("scripts/pipeline/get_data_bilateral.R")
  source("scripts/pipeline/get_data_imputed_org.R")
  source("scripts/pipeline/create_final_data.R")

  message("⬇️ Fetching OECD donor data for year: ", last_year_donors)
  df_dac_raw <- get_data_donors(last_year_donors)

  message("⬇️ Fetching imputed multilateral data for 10-year span ending in: ", last_year_imputed)
  df_imputed_raw <- get_data_imputed(last_year_imputed)

  message("⬇️ Fetching latest 10 years of bilateral data from statsys version: ", version)
  df_oda_ten <- get_data_bilateral(version)

  message("⬇️ Loading manually imputed multilateral aid by organization (latest available year)")
  df_imp_org_raw <- get_data_imputed_org()

  message("🧮 Creating final datasets...")
  create_final_data(
    df_dac_raw = df_dac_raw,
    df_imputed_raw = df_imputed_raw,
    df_oda_ten = df_oda_ten,
    df_imp_org_raw = df_imp_org_raw
  )

  # Dynamically list saved .rds files in data/final/
  output_dir <- here::here("data", "final")
  output_files <- list.files(output_dir, pattern = "\\.rds$", full.names = FALSE)

  message("✅ Data pipeline completed.")
  message("📁 The following files were saved to data/final/:")

  purrr::walk(output_files, \(x) message("  - ", x))
}
