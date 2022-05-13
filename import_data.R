# Scriptet laster inn datakilder som brukes i appen og inkluderer visuell mottakerland-kolonne i alle datafiler.
# Scriptet sources inn i scriptet app.R, og trenger dermed ikke å kjøres separat
# Datakildene lastes inn fra mappen data/

# Laster inn nødvendige pakker
library(readr)
library(dplyr)
library(readxl)
library(janitor)
library(noradstats)
library(here)

# Kilde A: Bistandsstatistikk 10 år (oda_ten)
df_oda_ten <- 
  noradstats::read_aiddata(here("data", "statsys_ten.csv")) |>
  filter(`Type of Flow` == "ODA") |>
  filter(`Type of agreement` != "Rammeavtale") |>
  filter(Year %in% max(Year-9):max(Year)) |> 
  
  # Velger variabler, grupperer og summerer
  group_by(`Recipient country CRS`,
           `Recipient country NO`,
           `Recipient country`,
           Year,
           `Type of Flow`,
           `Type of agreement`,
           `Target area`,
           `Group of Agreement Partner`,
           `Agreement partner`,
           `Main Region`,
           `Income category`) |>
  summarise(`Disbursed (mill NOK)` = sum(`Disbursed (mill NOK)`)) |>
  ungroup() |>
  
  # Inkluderer ekstra kolonner fra noradstats-pakken
  noradstats::add_cols_basic() |>
  
  # Rydder kolonnenavn
  janitor::clean_names()

# Datasett med mottakerland av øremerket bistand siste år. Skal filtrere datakildene på disse landene. ----
df_countries <- df_oda_ten |>
  filter(type_of_flow == "ODA") |>
  filter(type_of_agreement != "Rammeavtale") |>
  filter(income_category != "Unspecified") |>
  filter(year %in% max(year)) |>
  group_by(recipient_country_no, recipient_country_crs, recipient_country) |>
  summarise(total = sum(disbursed_mill_nok)) |>
  ungroup() |>
  filter(total > 0) |>
  filter(!is.na(recipient_country_no)) |>
  select(recipient_country_crs, recipient_country_no, recipient_country) |>
  arrange()

# Datasett med visudell landnavn. Skal inkluderes i alle datakilder ----------------------------------
# Visuelle landnavn på bistandsresultater.no (statsys-uttrekket land_og_regioner)
df_landreg_raw <- read_csv2(here("data", "land_og_regioner.csv")) |>
  janitor::clean_names() |> 
  select(navn_no, recipient_country_i_statsys, land_norsk) %>%
  rename("recipient_country_no_visual" = land_norsk)

# Kilde A: Bistandsstatistikk 10 år (oda_ten) ----
# Legger til kolonne med visuell landnavn
df_oda_ten <- left_join(x = df_oda_ten, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

# Kilde B. Imputed multilteral 10 år (kilde: OECDs imputed-data på https://stats.oecd.org/) ----
df_imp_raw <- read_excel(path = "data/imputed_multi_land.xlsx", sheet = 1) |>
  janitor::clean_names()

# Legger til kolonne med visuell landnavn
df_imp_raw <- left_join(x = df_imp_raw, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

# Kilde C. Imputed multilateral organisasjonsfordelt, ett år (kilde: tilsendt fra OECD) ----
df_imp_org_raw <- read_excel(path = "data/imputed_multi_land_org.xlsx") |>
  janitor::clean_names()

# Legger til kolonne med visuell landnavn
df_imp_org_raw <- left_join(x = df_imp_org_raw, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

# Kilde D. Internasjonal bistand fra DAC-land, ett år (kilde: OECDs CRS-data på https://stats.oecd.org/) ----
# df_dac_raw <- read_excel(path = "data/oecd_dac_donors.xlsx", sheet = 1) |>
#   janitor::clean_names()
# Legger til kolonne med visuell landnavn
# df_dac_raw <- left_join(x = df_dac_raw, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

df_dac_raw <- readr::read_csv(here("data", "dac_donors.csv")) |>
  janitor::clean_names()

# Filtrerer til kun land som mottok øremerket bistand fra Norge sist år
df_dac_raw <- df_dac_raw |> 
  filter(recipient %in% df_countries$recipient_country_crs)

# Legger til kolonne med crs landkode
df_dac_raw <- left_join(x = df_dac_raw, y = df_countries, by = c("recipient" = "recipient_country_crs"))

# Legger til kolonne med visuell landnavn
df_dac_raw <- left_join(x = df_dac_raw, y = df_landreg_raw, by = c("recipient_country" = "recipient_country_i_statsys"))

# Filtrerer vekk land uten beløp og velger kolonner
df_dac_raw <- df_dac_raw |> 
  filter(usd_mill != 0) |> 
  mutate(year = obs_time,
         oecd_donor_no = donor_label_en) |> 
  select(oecd_donor_no, recipient_country_no_visual, usd_mill, year)

rm(df_landreg_raw)