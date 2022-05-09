# Scriptet henter fra OECDs databaser DAC-lands ODA per mottakerland i år X

library(rsdmx)
library(tidyverse)
library(here)

# Velger år
vec_year <- 2019

# Her brukes OECD-datasettet TABLE2A inkludert metadata.
# For å spesifisere key-argumentet, så identifiser hvilke keys-dimensjoner som finnes i datasettet og kan spesifiseres. Punktum-tegnet skiller dimensjonene.

# Keys-argumentet:
# Punktum er skilletegnet mellom de fem keys.
# RECIPIENT: Oppgir ingen verdi (alle mottakerland)
# DONOR: De 29 DAC-landene (separtert med pluss)
# PART: 1 (utviklingsland)
# AIDTYPE: 206 (Total net ODA)
# DATATYPE A (Current prices)
# TIME (tid spesifiseres separat i start og end.)

# For å få med metadata (DSD) fyll inn dsd = TRUE

sdmx_dac <- readSDMX(
  providerId = "OECD",
  resource = "data",
  flowRef = "TABLE2A",
  key = ".801+1+2+301+68+3+18+4+5+40+75+20+21+6+701+742+22+7+820+8+76+9+69+61+50+10+11+12+302.1.206.A",
  key.mode = "SDMX",
  start = vec_year,
  end = vec_year,
  dsd = TRUE
)

# Strukturerer dsd til dataframe
df_dac <- as.data.frame(sdmx_dac, labels = TRUE) %>%
  as_tibble()

# Fjerner mottakerlandene regional og total
df_dac <- df_dac %>%
  filter(!str_detect(df_dac$RECIPIENT_label.en, "Total|regional"))

# Velger relevante kolonner og endrer navn på verdikolonnen
df_dac <- df_dac %>%
  select(AIDTYPE_label.en, DONOR, DONOR_label.en, RECIPIENT, RECIPIENT_label.en, obsTime, obsValue, POWERCODE_label.en, DATATYPE_label.en) %>%
  rename(usd_mill = obsValue)

# Lagrer i data-mappe
writexl::write_xlsx(df_dac, here("data", "df_dac.xlsx"))