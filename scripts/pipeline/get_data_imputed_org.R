# Retrieve manually imputed Norwegian multilateral aid to recipient countries by organisation ----
#
# Required packages must be loaded before calling the function:
# dplyr, readr, janitor, here

# Load required libraries ----
library(dplyr)
library(readr)
library(janitor)
library(here)

#' Retrieve manually imputed Norwegian multilateral aid to recipient countries by organisation for one year
#'
#' This function loads a manually maintained dataset that assigns estimated disbursements
#' of Norwegian multilateral aid to recipient countries, broken down by multilateral organizations.
#' The data is stored in `data/raw/imputed_multi_land_org.csv` and assumed to contain the most
#' recent available year.
#'
#' The function cleans column names, converts disbursements to millions of NOK,
#' and drops the original value column (`disbursed_nok`).
#'
#' @return A tibble containing manually imputed multilateral aid data
#'
#' @examples
#' df_imp_org_raw <- get_data_imputed_org()
#'
#' @export
get_data_imputed_org <- function() {

  # Read and prepare the manually maintained CSV:
  # - clean column names
  # - convert NOK values to millions
  # - drop original disbursed_nok column
  df_imp_org_raw <- readr::read_csv2(here::here("data", "raw", "imputed_multi_land_org.csv")) |>
    janitor::clean_names() |>
    dplyr::mutate(disbursed_mill_nok = disbursed_nok / 1e6) |>
    dplyr::select(-disbursed_nok)

  return(df_imp_org_raw)
}
