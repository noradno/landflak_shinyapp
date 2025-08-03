
# ---- Function: Create URL to the country page in Resultatportalen ----

run_result_portal_url <- function(
    data_nor_bilateral_raw = df_oda_ten,
    selected_country = params$selected_country
) {
  
  # -- Helper: Clean and convert country/region names to URL-friendly strings
  clean_for_url <- function(x) {
    x |>
      str_to_lower() |>
      str_replace_all(" ", "-") |>
      str_replace_all("[.]", "") |>
      str_squish() |>
      str_replace_all("æ", "ae") |>
      str_replace_all("ø", "oe") |>
      str_replace_all("å", "aa")
  }
  
  # -- Main logic --
  
  # Prepare country part of the URL
  val_url_country <- clean_for_url(selected_country)
  
  # Prepare region part of the URL
  val_url_region <- data_nor_bilateral_raw |>
    filter(recipient_country_en_visual == selected_country) |>
    select(main_region_no) |>
    distinct() |>
    pull() |>
    clean_for_url()
  
  # Construct full URL
  val_url <- paste0(
    "https://resultater.norad.no/bistands-tall/geografi/",
    val_url_region, "/", val_url_country
  )
  
  # -- Return outputs --
  list(
    val_url = val_url,
    val_url_region = val_url_region,
    val_url_country = val_url_country
  )
}
