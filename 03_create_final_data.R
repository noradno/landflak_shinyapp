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
df_oda_ten <- noradstats::access_oda() |> 
  filter(year > (max(year, na.rm = TRUE) - 9) & year <= max(year, na.rm = TRUE)) |> 
  
  # Velger variabler, grupperer og summerer
  group_by(recipient_country_crs,
           recipient_country_no,
           recipient_country,
           year,
           target_area,
           target_area_no,
           group_of_agreement_partner,
           partner_group_visual_no,
           agreement_partner,
           main_region,
           main_region_no,
           income_category) |>
  summarise(disbursed_mill_nok = sum(disbursed_mill_nok, na.rm = TRUE)) |>
  ungroup() |> 
  collect()

# Visuelle landnavn på bistandsresultater.no (statsys-uttrekket land_og_regioner)
df_landreg_raw <- read_csv2(here("data_raw_and_processed/raw", "land_og_regioner.csv")) |>
  janitor::clean_names() |> 
  select(navn_no, recipient_country_i_statsys, land_norsk) %>%
  rename("recipient_country_no_visual" = land_norsk)

# Legger til kolonne med visuell landnavn i oda_ten
df_oda_ten <- left_join(x = df_oda_ten, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

# Datasett med mottakerland av øremerket bistand siste år. Skal filtrere datakildene på disse landene. ----
df_countries <- df_oda_ten |>
  filter(income_category != "Unspecified") |>
  filter(year %in% max(year)) |>
  group_by(recipient_country_no, recipient_country_crs, recipient_country) |>
  summarise(total = sum(disbursed_mill_nok)) |>
  ungroup() |>
  filter(total > 0) |>
  filter(!is.na(recipient_country_no)) |>
  select(recipient_country_crs, recipient_country_no, recipient_country) |>
  arrange()

# # Datasett med mottakerland av øremerket bistand siste år. Skal filtrere datakildene på disse landene. ----
# df_countries <- readr::read_csv(here("data_final", "oda_countries.csv"))

# Datasett med visudell landnavn. Skal inkluderes i alle datakilder
# Visuelle landnavn på bistandsresultater.no (statsys-uttrekket land_og_regioner)
df_landreg_raw <- read_csv2(here("data_raw_and_processed/raw", "land_og_regioner.csv")) |>
  janitor::clean_names() |> 
  select(navn_no, recipient_country_i_statsys, land_norsk) %>%
  rename("recipient_country_no_visual" = land_norsk)

# Kilde B. Imputed multilteral 10 år. Fra mappen /data hentet av scriptet get_data_imputed.R ----

df_imp_raw <- readr::read_csv(here("data_raw_and_processed/processed", "nor_imputed.csv")) |>
  janitor::clean_names()

# Filtrerer til kun land som mottok øremerket bistand fra Norge sist år
df_imp_raw <- df_imp_raw |> 
  filter(crs_recipients_code %in% df_countries$recipient_country_crs)

# Legger til kolonne med crs landkode
df_imp_raw <- left_join(x = df_imp_raw, y = df_countries, by = c("crs_recipients_code" = "recipient_country_crs"))

# Legger til kolonne med visuell landnavn
df_imp_raw <- left_join(x = df_imp_raw, y = df_landreg_raw, by = c("recipient_country" = "recipient_country_i_statsys"))

# Filtrerer vekk land uten beløp og velger kolonner
df_imp_raw <- df_imp_raw |> 
  filter(usd_mill != 0) |> 
  mutate(year = obs_time,
         oecd_donor_no = donor_label_en,
         disbursed_mill_nok = nok_mill) |> 
  select(oecd_donor_no, recipient_country_no_visual, disbursed_mill_nok, year)

# Kilde C. Imputed multilateral organisasjonsfordelt, ett år. Fra mappen /data hentet av scriptet get_data_donors.R ----
df_imp_org_raw <- read_csv2(here("data_raw_and_processed/raw", "imputed_multi_land_org.csv")) |>
  janitor::clean_names() |> 
  mutate(disbursed_mill_nok = disbursed_nok / 1e6) |> 
  select(-disbursed_nok)

# Legger til kolonne med visuell landnavn
df_imp_org_raw <- left_join(x = df_imp_org_raw, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

# Kilde D. Internasjonal bistand fra DAC-land, ett år (kilde: OECDs CRS-data på https://stats.oecd.org/) ----

df_dac_raw <- readr::read_csv(here("data_raw_and_processed/processed", "dac_donors.csv")) |>
  janitor::clean_names()

# Filtrerer til kun land som mottok øremerket bistand fra Norge sist år
df_dac_raw <- df_dac_raw |> 
  filter(crs_recipients_code %in% df_countries$recipient_country_crs)

# Legger til kolonne med crs landkode
df_dac_raw <- left_join(x = df_dac_raw, y = df_countries, by = c("crs_recipients_code" = "recipient_country_crs"))

# Legger til kolonne med visuell landnavn
df_dac_raw <- left_join(x = df_dac_raw, y = df_landreg_raw, by = c("recipient_country" = "recipient_country_i_statsys"))

# Filtrerer vekk land uten beløp og velger kolonner
df_dac_raw <- df_dac_raw |> 
  filter(usd_mill != 0) |> 
  mutate(year = obs_time,
         oecd_donor_no = donor_label_en) |> 
  select(oecd_donor_no, recipient_country_no_visual, usd_mill, year)

rm(df_landreg_raw)

# Save objects in data_final folder
save(
  df_oda_ten,
  df_countries,
  df_dac_raw,
  df_imp_raw,
  df_imp_org_raw,
  file = here::here("data_final", "landflak_datasets.rda")
  )


