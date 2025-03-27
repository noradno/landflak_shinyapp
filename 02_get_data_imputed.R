# Scriptet henter fra OECDs databaser Norges imputed multilateral ODA til mottakerland i tidsperioden X til Y

library(rsdmx)
library(tidyverse)
library(here)

# Spesifiserer år
vec_endyear <- 2023
vec_startyear <- vec_endyear - 9

# Her brukes OECD-datasettet TABLE2A inkludert metadata.
# For å spesifisere key-argumentet, så identifiser hvilke keys-dimensjoner som finnes i datasettet og kan spesifiseres. Punktum-tegnet skiller dimensjonene.

# Keys-argumentet:
# Punktum er skilletegnet mellom de fem keys.
# RECIPIENT: Oppgir ingen verdi (alle mottakerland)
# DONOR: Norge (8))
# PART: 1 (utviklingsland)
# AIDTYPE: 206 (Total net ODA)
# DATATYPE A (Current prices)
# TIME (tid spesifiseres separat i start og end.)

# For å få med metadata (DSD) fyll inn dsd = TRUE

sdmx_imputed <- readSDMX(
  providerId = "OECD",
  resource = "data",
  flowRef = "DSD_DAC2@DF_DAC2A",
  key = "NOR..106.USD.V",
  key.mode = "SDMX",
  start = vec_startyear,
  end = vec_endyear,
  dsd = TRUE
)

# Inkluder argument labels= TRUE for å få med metadata-kolonner
df_imputed <- as.data.frame(sdmx_imputed, labels = TRUE) |> 
  as_tibble()

# Fjerner mottakerlandene regional og total
df_imputed <- df_imputed |> 
  filter(!str_detect(df_imputed$RECIPIENT_label.en, "Total|regional"))

# Velger relevante kolonner og gir nytt navn til verdikolonne
df_imputed <- df_imputed |> 
  select(MEASURE_label.en, DONOR, DONOR_label.en, RECIPIENT, RECIPIENT_label.en, obsTime, obsValue, UNIT_MULT_label.en.label, PRICE_BASE_label.en) |> 
  rename(usd_mill = obsValue)

# Include CRS country codes (donors and recipients) from separate sheet -----------------------------------------------------------------------------------------
df_oecd_donors_code <- read_csv2(here("data_raw_and_processed/raw", "crs_donors_code.csv"))
df_oecd_recipients_code <- read_csv2(here("data_raw_and_processed/raw", "crs_recipients_code.csv"))

# Include crs_donors_code and oecd_recipients_code using iso country code as key
df_imputed <- df_imputed |> 
  left_join(df_oecd_donors_code, join_by(DONOR == iso_code)) |> 
  left_join(df_oecd_recipients_code, join_by(RECIPIENT == iso_code))

df_imputed <- df_imputed |> 
  mutate(
    crs_donors_code = as.integer(crs_donors_code),
    crs_recipients_code = as.integer(crs_recipients_code)
  )

# Remove observations with NA crs_recipients_code (removes regions, global etc)
df_imputed <- df_imputed |> 
  filter(!is.na(crs_recipients_code))

# Vekslingskurs NOR - USD fra OECD (bruker csv istedet for API fordi APIet over ikke har bistands-vekslingskurser) ----------------------------------------

df_exchangerate <- read_csv2(here("data_raw_and_processed/raw", "exchangerate.csv"))

df_exchangerate <- df_exchangerate |> 
  rename(exchangerate = obsValue) |> 
  mutate(obsTime = as.character(obsTime))

# Inkluderer vekslingskurs-kolonne i df_imputed datasett------------------

# Lager vekslingskur-kolonne for riktig år
df_imputed <- left_join(df_imputed, df_exchangerate, by = "obsTime")

# Ny kolonne nok_mill basert på vekslingskurs
df_imputed <- df_imputed %>%
  mutate(nok_mill = usd_mill * exchangerate)

# Lagrer i data-mappe
readr::write_csv(df_imputed, here("data_raw_and_processed/processed", "nor_imputed.csv"))
