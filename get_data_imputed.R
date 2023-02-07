# Scriptet henter fra OECDs databaser Norges imputed multilateral ODA til mottakerland i tidsperioden X til Y

library(rsdmx)
library(tidyverse)
library(here)

# Spesifiserer år
vec_endyear <- 2021
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
  flowRef = "TABLE2A",
  key = ".8.1.106.A",
  key.mode = "SDMX",
  start = vec_startyear,
  end = vec_endyear,
  dsd = TRUE
)

# Inkluder argument labels= TRUE for å få med metadata-kolonner
df_imputed <- as.data.frame(sdmx_imputed, labels = TRUE) %>%
  as_tibble()

# Fjerner mottakerlandene regional og total
df_imputed <- df_imputed %>%
  filter(!str_detect(df_imputed$RECIPIENT_label.en, "Total|regional"))

# Velger relevante kolonner og gir nytt navn til verdikolonne
df_imputed <- df_imputed %>%
  select(AIDTYPE_label.en, DONOR, DONOR_label.en, RECIPIENT, RECIPIENT_label.en, obsTime, obsValue, POWERCODE_label.en, DATATYPE_label.en) %>%
  rename(usd_mill = obsValue)


# Vekslingskurs NOR - USD fra OECD ----------------------------------------

# Her brukes OECD-datasettet SNA_TABLE4, uten metadata
# URLen er hentet fra nettsiden oecd.stat under National accounts -> Annual National Accounts -> Main aggregates -> 4.PPPs and exchange rates.
# Har spesifisert URL-en til å filtrere på dimensjonene NOR.EXC.CD. Se i Annex for å idendtifisere dimensjonene, deres rekkefølge og verdier for filtrering.

# sdmx_exchangerate <- readSDMX(
#   providerId = "OECD",
#   resource = "data",
#   flowRef = "SNA_TABLE4",
#   key = "NOR.EXC.CD",
#   key.mode = "SDMX",
#   start = vec_startyear,
#   end = vec_endyear,
#   dsd = TRUE
# )

# Inkluder argument labels= TRUE for å få med metadata-kolonner
# df_exchangerate <- as.data.frame(sdmx_exchangerate) %>%
#   as_tibble()

# Velger relevante kolonner og gir nytt navn til verdikolonne
# df_exchangerate <- df_exchangerate %>%
#   select(obsTime, obsValue) %>%
#   rename(exchangerate = obsValue)

# Vekslingskurs NOR - USD fra OECD (bruker csv istedet for API fordi APIet over ikke har bistands-vekslingskurser) ----------------------------------------

df_exchangerate <- read_csv2(here("data", "exchangerate.csv"))

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
readr::write_csv(df_imputed, here("data", "nor_imputed.csv"))
