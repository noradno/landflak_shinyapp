# Scriptet henter fra OECDs databaser DAC-lands ODA per mottakerland i år X

library(rsdmx)
library(tidyverse)
library(here)

# Velger år
vec_year <- 2023

# Her brukes OECD-datasettet TABLE2A inkludert metadata.
# For å spesifisere key-argumentet, så identifiser hvilke keys-dimensjoner som finnes i datasettet og kan spesifiseres. Punktum-tegnet skiller dimensjonene.

# Keys-argumentet:
# Punktum er skilletegnet mellom de fem keys.
# RECIPIENT: Oppgir ingen verdi (alle mottakerland)
# DONOR: De 31 DAC-landene (separtert med pluss)
# AIDTYPE: 206 (Total net ODA)
# DATATYPE A (Current prices)
# TIME (tid spesifiseres separat i start og end.)

# For å få med metadata (DSD) fyll inn dsd = TRUE

sdmx_dac <- readSDMX(
  providerId = "OECD",
  resource = "data",
  flowRef = "DSD_DAC2@DF_DAC2A",
  start = vec_year,
  end = vec_year,
  key = list("USA+CHE+GBR+ESP+SVN+SWE+SVK+PRT+POL+NOR+NZL+NLD+LUX+LTU+KOR+JPN+ITA+IRL+ISL+HUN+GRC+DEU+FRA+FIN+EST+DNK+CZE+AUT+CAN+BEL+AUS..206.USD.V"),
 dsd = TRUE)

# Strukturerer dsd til dataframe
df_dac <- as.data.frame(sdmx_dac, labels = TRUE) |> 
  as_tibble()

# Fjerner mottakerlandene regional og total
df_dac <- df_dac |> 
  filter(!str_detect(df_dac$RECIPIENT_label.en, "Total|regional"))

# Velger relevante kolonner og endrer navn på verdikolonnen
df_dac <- df_dac |> 
  select(MEASURE_label.en, DONOR, DONOR_label.en, RECIPIENT, RECIPIENT_label.en, obsTime, obsValue, UNIT_MULT_label.en.label, PRICE_BASE_label.en) %>%
  rename(usd_mill = obsValue)

# Include CRS country codes (donors and recipients) from separate sheet -----------------------------------------------------------------------------------------
df_oecd_donors_code <- read_csv2(here("data_raw_and_processed/raw", "crs_donors_code.csv"))
df_oecd_recipients_code <- read_csv2(here("data_raw_and_processed/raw", "crs_recipients_code.csv"))

# Include crs_donors_code and oecd_recipients_code using iso country code as key
df_dac <- df_dac |> 
  left_join(df_oecd_donors_code, join_by(DONOR == iso_code)) |> 
  left_join(df_oecd_recipients_code, join_by(RECIPIENT == iso_code))

df_dac <- df_dac |> 
  mutate(
    crs_donors_code = as.integer(crs_donors_code),
    crs_recipients_code = as.integer(crs_recipients_code)
  )

# Remove observations with NA crs_recipients_code (removes regions, global etc)
df_dac <- df_dac |> 
  filter(!is.na(crs_recipients_code))

# Lagrer i data-mappe
readr::write_csv(df_dac, here("data_raw_and_processed/processed", "dac_donors.csv"))
