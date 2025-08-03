# Create and write final cleaned datasets for Shiny app ----
# 
# This script defines a function that merges and transforms raw datasets
# into the final cleaned datasets used by the Country Snapshot Shiny app.
# Required packages must be loaded before calling the function.

# Load required libraries ----
library(dplyr)
library(readr)
library(janitor)
library(here)

#' Create and write final cleaned datasets for Shiny app
#'
#' This function merges and transforms raw datasets into the final cleaned datasets used by the
#' Country Snapshot Shiny app. Most data preprocessing steps (such as fetching and cleaning raw sources)
#' have already been handled in prior steps using dedicated `get_*()` functions. This function represents
#' the final assembly step before saving the cleaned data.
#'
#' It enriches bilateral aid data with region names, filters eligible countries, and prepares final datasets
#' used directly in reporting and the user interface. The results are saved as `.rds` files to the `data/final/` folder.
#'
#' Input data must be provided via the following functions: 
#' - `get_data_donors()`
#' - `get_data_imputed()`
#' - `get_data_bilateral()`
#' - `get_data_imputed_org()`
#'
#' The function produces five output datasets:
#' - `df_oda_ten.rds`: Bilateral aid from Statsys (last 10 years)
#' - `df_dac_raw.rds`: Cleaned OECD bilateral data
#' - `df_imp_raw.rds`: Cleaned OECD imputed multilateral aid (10 years)
#' - `df_imp_org_raw.rds`: Manually imputed multilateral aid by organization
#' - `df_countries.rds`: List of eligible recipient countries for reporting
#'
#' @param df_dac_raw OECD bilateral donor data (from `get_data_donors()`)
#' @param df_imputed_raw Imputed multilateral data (from `get_data_imputed()`)
#' @param df_oda_ten Bilateral Statsys data (from `get_data_bilateral()`)
#' @param df_imp_org_raw Manually imputed multilateral aid (from `get_data_imputed_org()`)
#'
#' @return Saves cleaned `.rds` files to `data/final/`
#'
#' @examples
#' create_final_data(df_dac_raw, df_imputed_raw, df_oda_ten, df_imp_org_raw)
#'
#' @export
create_final_data <- function(df_dac_raw, df_imputed_raw, df_oda_ten, df_imp_org_raw) {
  
  # Read mapping of countries and regions
  df_landreg_raw <- read_csv2(here("data", "raw", "land_og_regioner.csv")) |> 
    clean_names() |> 
    select(navn_no, land_engelsk) |> 
    rename(recipient_country_en_visual = land_engelsk)
  
  # Finalize Norwegian bilateral data
  df_oda_ten <- df_oda_ten |> 
    left_join(df_landreg_raw, by = c("recipient_country_no" = "navn_no"))
  
  # Generate list of eligible countries for reporting and filtering
  df_countries <- df_oda_ten |> 
    filter(
      income_category != "Unspecified",
      year == max(df_oda_ten$year, na.rm = TRUE),
      !is.na(recipient_country_en_visual)
    ) |> 
    group_by(recipient_country_en_visual, recipient_country_crs) |> 
    summarise(total = sum(disbursed_mill_nok), .groups = "drop") |> 
    filter(total > 0) |> 
    select(recipient_country_en_visual, recipient_country_crs) |> 
    arrange()
  
  # Finalize imputed multilateral aid
  df_imp_raw <- df_imputed_raw |> 
    filter(nok_mill != 0) |> 
    select(donor_label_en, crs_recipients_code, obs_time, nok_mill) |> 
    rename(
      year = obs_time,
      oecd_donor_no = donor_label_en,
      disbursed_mill_nok = nok_mill
    ) |> 
    left_join(df_countries, by = c("crs_recipients_code" = "recipient_country_crs")) |> 
    filter(!is.na(recipient_country_en_visual))
  
  # Finalize manually imputed org-level data
  df_imp_org_raw <- df_imp_org_raw |> 
    left_join(df_landreg_raw, by = c("recipient_country_no" = "navn_no")) |> 
    filter(recipient_country_en_visual %in% df_countries$recipient_country_en_visual) |> 
    select(multilateral_organisasjon, recipient_country_en_visual, year, disbursed_mill_nok)
  
  # Finalize OECD DAC data
  df_dac_clean <- df_dac_raw |> 
    filter(usd_mill != 0) |> 
    select(donor_label_en, crs_donors_code, crs_recipients_code, obs_time, usd_mill) |> 
    rename(
      year = obs_time,
      oecd_donor_no = donor_label_en
    ) |> 
    left_join(df_countries, by = c("crs_recipients_code" = "recipient_country_crs")) |> 
    filter(!is.na(recipient_country_en_visual))
  
  # Save to disk
  write_rds(df_oda_ten, here("data", "final", "df_oda_ten.rds"))
  write_rds(df_dac_clean, here("data", "final", "df_dac_raw.rds"))
  write_rds(df_imp_raw, here("data", "final", "df_imp_raw.rds"))
  write_rds(df_imp_org_raw, here("data", "final", "df_imp_org_raw.rds"))
  write_rds(df_countries, here("data", "final", "df_countries.rds"))
}
