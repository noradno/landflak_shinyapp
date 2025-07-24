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
  library(dplyr)
  library(readr)
  library(janitor)
  library(here)
  
  # Read and prepare the manually maintained CSV: clean names, convert to NOK million
  df_imp_org_raw <- read_csv2(here("data", "raw", "imputed_multi_land_org.csv")) |> 
    janitor::clean_names() |> 
    mutate(disbursed_mill_nok = disbursed_nok / 1e6) |> 
    select(-disbursed_nok)
  
  return(df_imp_org_raw)
}
