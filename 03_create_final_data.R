# Scriptet laster inn data som brukes i appen og inkluderer visuell mottakerland-kolonne i alle datafiler.
# Scriptet sources inn i scriptet app.R, og trenger dermed ikke å kjøres separat
# Datakildene lastes inn fra mappen data/

# Laster inn nødvendige pakker
library(readr)
library(dplyr)
library(readxl)
library(janitor)
library(noradstats)
library(here)

# Load, process and write oda_ten.csv and oda_countries.csv to data/processed directory

# Kilde A: Bistandsstatistikk 10 år (oda_ten)

# IMPORTANT USER INPUT: Specify statsys_active (not offical statistics) or statsys_official (official statistics)
vec_statsys_version <- "statsys_active"

df_oda_ten <- noradstats::access_statsys(version = vec_statsys_version) |> 
  filter(
    type_of_flow == "ODA",
    type_of_agreement != "Rammeavtale",
    year > (max(year, na.rm = TRUE) - 9) & year <= max(year, na.rm = TRUE)
    ) |> 
  
  # Velger variabler, grupperer og summerer
  group_by(recipient_country_crs,
           recipient_country_no,
           recipient_country,
           year,
           target_area,
           group_of_agreement_partner,
           partner_group_visual,
           agreement_partner,
           main_region,
           main_region_no,
           income_category) |>
  summarise(disbursed_mill_nok = sum(disbursed_mill_nok, na.rm = TRUE)) |>
  ungroup() |> 
  collect()

# Visuelle landnavn på bistandsresultater.no (statsys-uttrekket land_og_regioner)
# Variabelen navn_no tilsvarer recipient_country_no i statsys_uttrekket, og brukes som noekkel.
df_landreg_raw <- read_csv2(here("data_raw_and_processed/raw", "land_og_regioner.csv")) |>
  janitor::clean_names() |> 
  select(navn_no, land_engelsk) %>%
  rename("recipient_country_en_visual" = land_engelsk)

# Legger til kolonne med visuell landnavn i oda_ten
df_oda_ten <- left_join(x = df_oda_ten, y = df_landreg_raw, join_by(recipient_country_no == navn_no))

# Datasett med visuelle mottakerland av netto mottakere av øremerket bistand siste år. Skal filtrere datakildene på disse landene. ----
df_countries <- df_oda_ten |>
  filter(
    income_category != "Unspecified",
    year %in% max(year),
    !is.na(recipient_country_en_visual)
    ) |>
  group_by(recipient_country_en_visual, recipient_country_crs) |>
  summarise(total = sum(disbursed_mill_nok)) |>
  ungroup() |>
  filter(total > 0) |>
  select(recipient_country_en_visual, recipient_country_crs) |> 
  arrange()

# Kilde B. Imputed multilteral 10 år. Fra mappen /data hentet av scriptet get_data_imputed.R ----

df_imp_raw <- readr::read_csv(here("data_raw_and_processed/processed", "nor_imputed.csv")) |>
  janitor::clean_names()

# Inkluderer kun land med beløp og velger relevante variabler og gir nye kolonnenavn.
df_imp_raw <- df_imp_raw |> 
  filter(nok_mill != 0) |> 
  select(donor_label_en, crs_recipients_code, obs_time, nok_mill) |> 
  rename(
    year = obs_time,
    oecd_donor_no = donor_label_en,
    disbursed_mill_nok = nok_mill
    )

# Legger til kolonne med crs landkode fra df_countries med kun land som mottok øremerket bistand fra Norge sist år.
df_imp_raw <- df_imp_raw |> 
  left_join(df_countries, join_by(crs_recipients_code == recipient_country_crs)) |> 
  filter(!is.na(recipient_country_en_visual))

# Kilde C. Imputed multilateral organisasjonsfordelt, ett år. Fra mappen /data hentet av scriptet get_data_donors.R ----
df_imp_org_raw <- read_csv2(here("data_raw_and_processed/raw", "imputed_multi_land_org.csv")) |>
  janitor::clean_names()

# Omkoder beløpskolonne og beholder relevante kolonner
df_imp_org_raw <- df_imp_org_raw |> 
  mutate(disbursed_mill_nok = disbursed_nok / 1e6) |> 
  select(-disbursed_nok)

# Legger til kolonne med visuell landnavn. Må her bruke df_landreg_raw for å hente visuelle landnavn fordi landkode i crs format ikke er i datasettet dessverre.
df_imp_org_raw <- df_imp_org_raw |> 
  left_join(df_landreg_raw, join_by(recipient_country_no == "navn_no"))

# Inkluderer kun land som mottok øremerket bistand fra Norge sist år.
df_imp_org_raw <- df_imp_org_raw |> 
  filter(recipient_country_en_visual %in% df_countries$recipient_country_en_visual)

# Beholder kun relevante kolonner
df_imp_org_raw <- df_imp_org_raw |> 
  select(multilateral_organisasjon, recipient_country_en_visual, year, disbursed_mill_nok)

# Kilde D. Internasjonal bistand fra DAC-land, ett år (kilde: OECDs CRS-data på https://stats.oecd.org/) ----

df_dac_raw <- readr::read_csv(here("data_raw_and_processed/processed", "dac_donors.csv")) |>
  janitor::clean_names()

# Inkluderer kun land med beløp og velger relevante variabler og gir nye kolonnenavn.
df_dac_raw <- df_dac_raw |> 
  filter(usd_mill != 0) |> 
  select(donor_label_en, crs_donors_code, crs_recipients_code, obs_time, usd_mill) |> 
  rename(
    year = obs_time,
    oecd_donor_no = donor_label_en
  )

# Legger til kolonne med crs landkode fra df_countries med kun land som mottok øremerket bistand fra Norge sist år.
df_dac_raw <- df_dac_raw |> 
  left_join(df_countries, join_by(crs_recipients_code == recipient_country_crs)) |> 
  filter(!is.na(recipient_country_en_visual))

# Save objects in data_final folder
save(
  df_oda_ten,
  df_dac_raw,
  df_imp_raw,
  df_imp_org_raw,
  file = here::here("data_final", "landflak_datasets.rda")
  )

# Save separate object of countries
save(
  df_countries, 
  file = here::here("data_final", "countries.rda")
)


