# Download and prepare international OECD DAC donor data to recipient countries for the last year ----
#
# Required packages must be loaded before calling the function:
# rsdmx, dplyr, readr, stringr, janitor, here

# Load required libraries ----
library(rsdmx)
library(tidyverse)  # For dplyr, tibble, stringr
library(janitor)
library(here)

#' Download and prepare international OECD DAC donor data to recipient countries for the last year
#'
#' Fetches disbursement data for bilateral donors from the OECD SDMX API
#' for a single year. It includes CRS codes by joining with local CSV code lists
#' and filters out regional and total aggregates.
#'
#' @param last_year Numeric year to fetch (e.g., 2023)
#'
#' @return A tibble with donor disbursement data, CRS codes added
#'
#' @examples
#' df_dac <- get_data_donors(last_year = 2023)
#'
#' @export
get_data_donors <- function(last_year) {

  # Fetch SDMX data for selected DAC donors and purpose code 206 (All sectors)
  sdmx_dac <- rsdmx::readSDMX(
    providerId = "OECD",
    resource = "data",
    flowRef = "DSD_DAC2@DF_DAC2A",
    start = last_year,
    end = last_year,
    key = list("USA+CHE+GBR+ESP+SVN+SWE+SVK+PRT+POL+NOR+NZL+NLD+LUX+LTU+KOR+JPN+ITA+IRL+ISL+HUN+GRC+DEU+FRA+FIN+EST+DNK+CZE+AUT+CAN+BEL+AUS..206.USD.V"),
    dsd = TRUE
  )

  # Convert to tibble and clean column names
  df_dac <- as.data.frame(sdmx_dac, labels = TRUE) |>
    as_tibble() |>
    janitor::clean_names()

  # Keep only country-level observations (exclude regional and total aggregates)
  df_dac <- df_dac |>
    dplyr::filter(!stringr::str_detect(recipient_label_en, "Total|regional")) |>
    dplyr::select(
      measure_label_en, donor, donor_label_en, recipient, recipient_label_en,
      obs_time, usd_mill = obs_value, unit_mult_label_en_label, price_base_label_en
    )

  # Load local CRS code mappings for donors and recipients
  df_donors_code <- readr::read_csv2(here::here("data", "raw", "crs_donors_code.csv"))
  df_recipients_code <- readr::read_csv2(here::here("data", "raw", "crs_recipients_code.csv"))

  # Join with CRS codes and filter out recipients without CRS codes
  df_dac <- df_dac |>
    dplyr::left_join(df_donors_code, join_by(donor == iso_code)) |>
    dplyr::left_join(df_recipients_code, join_by(recipient == iso_code)) |>
    dplyr::mutate(
      crs_donors_code = as.integer(crs_donors_code),
      crs_recipients_code = as.integer(crs_recipients_code)
    ) |>
    dplyr::filter(!is.na(crs_recipients_code))

  return(df_dac)
}
