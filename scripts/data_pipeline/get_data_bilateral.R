#' Retrieve Norwegian bilateral (earmarked) ODA disbursements to recipient countries for the last 10 years
#'
#' This function fetches Official Development Assistance (ODA) disbursement data from Norad's internal system
#' (Statsys) using the `noradstats::access_statsys()` function. It filters the data to include only actual ODA disbursements
#' (excluding framework agreements) over the last 10 available years.
#'
#' The function returns disbursement amounts in NOK millions by recipient country, region, year, and agreement characteristics.
#'
#' @param version A character string specifying the Statsys version to use, "statsys_official" or "statsys_active". Default is "statsys_official".
#' @return A tibble containing cleaned bilateral ODA data from Statsys
#'
#' @examples
#' df_oda_ten <- get_data_bilateral(version = "statsys_official")
#'
#' @export
get_data_bilateral <- function(version = "statsys_official") {
  library(dplyr)
  library(readr)
  library(janitor)
  library(readxl)
  library(here)
  
  # Access Statsys in DuckDB and filter for ODA disbursements (excluding framework agreements)
  df_oda_ten <- noradstats::access_statsys(version = version) |> 
    filter(
      type_of_flow == "ODA",
      type_of_agreement != "Rammeavtale",
      year > (max(year, na.rm = TRUE) - 9) & year <= max(year, na.rm = TRUE)
    ) |> 
    # Aggregate by recipient and agreement characteristics
    group_by(recipient_country_crs, recipient_country_no, recipient_country, year, target_area,
             group_of_agreement_partner, partner_group_visual, agreement_partner, main_region,
             main_region_no, income_category) |> 
    summarise(disbursed_mill_nok = sum(disbursed_mill_nok, na.rm = TRUE), .groups = "drop") |> 
    collect()  # Collect the database query into a tibble
  
  return(df_oda_ten)
}
