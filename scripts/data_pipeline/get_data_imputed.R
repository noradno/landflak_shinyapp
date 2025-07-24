#' Download and prepare imputed Norwegian multilateral ODA data to recipient countries for the last 10 years
#'
#' This function downloads Official Development Assistance (ODA) data reported by Norway
#' to the OECD DAC using the SDMX API. It retrieves imputed multilateral aid (purpose code 106)
#' for the last 10 years ending in `last_year`, converts the values from USD to NOK using exchange rates,
#' and appends donor/recipient CRS codes.
#'
#' @param last_year Integer indicating the final year of the 10-year time span to download data for
#'
#' @return A tibble containing cleaned imputed disbursements (in NOK millions) by recipient country
#' 
#' #' @examples
#' df_imputed <- get_data_imputed(last_year = 2023)
#' 
#' @export
get_data_imputed <- function(last_year) {
  library(rsdmx)
  library(tidyverse)
  library(here)
  library(janitor)
  
  start_year <- last_year - 9
  
  sdmx_imputed <- readSDMX(
    providerId = "OECD",
    resource = "data",
    flowRef = "DSD_DAC2@DF_DAC2A",
    key = "NOR..106.USD.V",
    key.mode = "SDMX",
    start = start_year,
    end = last_year,
    dsd = TRUE
  )
  
  df_imputed <- as.data.frame(sdmx_imputed, labels = TRUE) |> 
    as_tibble() |> 
    janitor::clean_names()
  
  df_imputed <- df_imputed |> 
    filter(!str_detect(recipient_label_en, "Total|regional")) |> 
    select(measure_label_en, donor, donor_label_en, recipient, recipient_label_en, obs_time, usd_mill = obs_value, unit_mult_label_en_label, price_base_label_en)
  
  df_donors_code <- read_csv2(here("data", "raw", "crs_donors_code.csv"))
  df_recipients_code <- read_csv2(here("data", "raw", "crs_recipients_code.csv"))
  df_exchangerate <- read_csv2(here("data", "raw", "exchangerate.csv")) |> 
    janitor::clean_names() |> 
    rename(exchangerate = obs_value) |> 
    mutate(obs_time = as.character(obs_time))
  
  df_imputed <- df_imputed |> 
    left_join(df_donors_code, join_by(donor == iso_code)) |> 
    left_join(df_recipients_code, join_by(recipient == iso_code)) |> 
    mutate(
      crs_donors_code = as.integer(crs_donors_code),
      crs_recipients_code = as.integer(crs_recipients_code)
    ) |> 
    filter(!is.na(crs_recipients_code)) |> 
    left_join(df_exchangerate, by = "obs_time") |> 
    mutate(nok_mill = usd_mill * exchangerate)
  
  return(df_imputed)
}