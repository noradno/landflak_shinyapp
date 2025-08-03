# Download and prepare imputed Norwegian multilateral ODA data to recipient countries for the last 10 years ----
#
# Required packages must be loaded before calling the function:
# rsdmx, dplyr, readr, stringr, janitor, here

# Load required libraries ----
library(rsdmx)
library(tidyverse)  # includes dplyr, readr, stringr, tibble
library(janitor)
library(here)

#' Download and prepare imputed Norwegian multilateral ODA data to recipient countries for the last 10 years
#'
#' This function downloads Official Development Assistance (ODA) data reported by Norway
#' to the OECD DAC using the SDMX API. It retrieves imputed multilateral aid
#' for the last 10 years ending in `last_year`, converts the values from USD to NOK using exchange rates,
#' and appends donor/recipient CRS codes.
#'
#' @param last_year Integer indicating the final year of the 10-year time span to download data for
#'
#' @return A tibble containing cleaned imputed disbursements (in NOK millions) by recipient country
#'
#' @examples
#' df_imputed <- get_data_imputed(last_year = 2023)
#'
#' @export
get_data_imputed <- function(last_year) {
  
  # Define start of 10-year window
  start_year <- last_year - 9

  # Fetch SDMX data for imputed multilateral aid (purpose code 106 = general budget support)
  sdmx_imputed <- rsdmx::readSDMX(
    providerId = "OECD",
    resource = "data",
    flowRef = "DSD_DAC2@DF_DAC2A",
    key = "NOR..106.USD.V",
    key.mode = "SDMX",
    start = start_year,
    end = last_year,
    dsd = TRUE
  )

  # Convert to tibble and clean column names
  df_imputed <- as.data.frame(sdmx_imputed, labels = TRUE) |>
    as_tibble() |>
    janitor::clean_names()

  # Filter out aggregates (e.g., totals and regional groupings), keep relevant columns
  df_imputed <- df_imputed |>
    dplyr::filter(!stringr::str_detect(recipient_label_en, "Total|regional")) |>
    dplyr::select(
      measure_label_en, donor, donor_label_en, recipient, recipient_label_en,
      obs_time, usd_mill = obs_value, unit_mult_label_en_label, price_base_label_en
    )

  # Load local code mappings and exchange rates
  df_donors_code <- readr::read_csv2(here::here("data", "raw", "crs_donors_code.csv"))
  df_recipients_code <- readr::read_csv2(here::here("data", "raw", "crs_recipients_code.csv"))
  df_exchangerate <- readr::read_csv2(here::here("data", "raw", "exchangerate.csv")) |>
    janitor::clean_names() |>
    dplyr::rename(exchangerate = obs_value) |>
    dplyr::mutate(obs_time = as.character(obs_time))

  # Join with code lists and exchange rates, calculate NOK values
  df_imputed <- df_imputed |>
    dplyr::left_join(df_donors_code, join_by(donor == iso_code)) |>
    dplyr::left_join(df_recipients_code, join_by(recipient == iso_code)) |>
    dplyr::mutate(
      crs_donors_code = as.integer(crs_donors_code),
      crs_recipients_code = as.integer(crs_recipients_code)
    ) |>
    dplyr::filter(!is.na(crs_recipients_code)) |>
    dplyr::left_join(df_exchangerate, by = "obs_time") |>
    dplyr::mutate(nok_mill = usd_mill * exchangerate)

  return(df_imputed)
}
