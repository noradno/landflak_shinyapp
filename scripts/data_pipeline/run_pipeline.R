#' Run the full data pipeline to produce cleaned and joined datasets of international and norwegian ODA to recipient countries
#'
#' This function runs the full data processing pipeline:
#' 1. Downloads raw DAC donor and imputed multilateral data from OECD using SDMX API
#' 2. Loads bilateral aid data from Norad's internal statsys database (last 10 years)
#' 3. Loads manually imputed multilateral disbursements by organization (latest year)
#' 4. Cleans and joins data, filters valid countries, and writes final `.rds` outputs
#'
#' @param last_year_donors Year to fetch DAC donor data for (default: 2023)
#' @param last_year_imputed Last year in 10-year range to fetch imputed multilateral data (default: 2023)
#'
#' @examples
#' run_pipeline(last_year_donors = 2023, last_year_imputed = 2023)
run_pipeline <- function(last_year_donors = 2023, last_year_imputed = 2023) {
  message("📦 Loading data pipeline functions...")
  source("scripts/data_pipeline/get_data_donors.R")
  source("scripts/data_pipeline/get_data_imputed.R")
  source("scripts/data_pipeline/get_data_bilateral.R")
  source("scripts/data_pipeline/get_data_imputed_org.R")
  source("scripts/data_pipeline/create_final_data.R")
  
  message("⬇️ Fetching OECD donor data for year: ", last_year_donors)
  df_dac_raw <- get_data_donors(last_year_donors)
  
  message("⬇️ Fetching imputed multilateral data for 10-year span ending in: ", last_year_imputed)
  df_imputed_raw <- get_data_imputed(last_year_imputed)
  
  message("⬇️ Fetching bilateral data from statsys (latest 10 years available)")
  df_oda_ten <- get_data_bilateral()
  
  message("⬇️ Loading manually imputed multilateral aid by organization (latest available year)")
  df_imp_org_raw <- get_data_imputed_org()
  
  message("🧮 Creating final datasets...")
  create_final_data(
    df_dac_raw = df_dac_raw,
    df_imputed_raw = df_imputed_raw,
    df_oda_ten = df_oda_ten,
    df_imp_org_raw = df_imp_org_raw
  )
  
  message("✅ Data pipeline completed.")
}