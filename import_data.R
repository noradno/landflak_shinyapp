# Scriptet laster inn datakilder som brukes i appen og inkluderer visuell mottakerland-kolonne i alle datafiler.
# Scriptet sources inn i scriptet app.R, og trenger dermed ikke å kjøres separat
# Datakildene lastes inn fra mappen data/

# Laster inn nødvendige pakker
library(dplyr)
library(readxl)
library(janitor)
library(noradstats)


# Kilde A: Bistandsstatistikk 10 år (oda_ten)
df_oda_ten <- 
  noradstats::read_aiddata("oda_ten.csv", subdir = TRUE) |>
  
  # Velger variabler, grupperer og summerer
  group_by(`Recipient country NO`,
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

# Kilde B. Imputed multilteral 10 år (kilde: OECDs imputed-data på https://stats.oecd.org/)
df_imp_raw <- read_excel(path = "data/imputed_multi_land.xlsx", sheet = 1) |>
  janitor::clean_names()

# Kilde C. Imputed multilateral organisasjonsfordelt, ett år (kilde: tilsendt fra OECD)
df_imp_org_raw <- read_excel(path = "data/imputed_multi_land_org.xlsx") |>
  janitor::clean_names()

# Kilde D. Internasjonal bistand fra DAC-land, ett år (kilde: OECDs CRS-data på https://stats.oecd.org/)
df_dac_raw <- read_excel(path = "data/oecd_dac_donors.xlsx", sheet = 1) |>
  janitor::clean_names()

# Kilde E. visuelle landnavn på bistandsresultater.no (statsys-uttrekket land_og_regioner)
df_landreg_raw <- read_excel(path = "data/land_og_regioner.xlsx") |>
  janitor::clean_names()


# Visudell landkolonne i alle datakilder ----------------------------------
# Kolonnen hentes fra df_landreg_raw

df_landreg_raw <- df_landreg_raw %>%
  select(navn_no, land_norsk) %>%
  rename("recipient_country_no_visual" = land_norsk)

df_oda_ten <- left_join(x = df_oda_ten, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

df_dac_raw <- left_join(x = df_dac_raw, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

df_imp_raw <- left_join(x = df_imp_raw, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

df_imp_org_raw <- left_join(x = df_imp_org_raw, y = df_landreg_raw, by = c("recipient_country_no" = "navn_no"))

rm(df_landreg_raw)
