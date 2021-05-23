# Scriptet laster inn datakilder som brukes i appen. Scriptet sources inn i appen.
# Datakildene lastes inn fra mappen data/

# Laster inn nødvendige pakker
library(vroom)
library(dplyr)
library(readxl)
library(janitor)
library(noradstats)


# Kilde A: Bistandsstatistikk 10 år (statsys-data)
#noradstats::download_aiddata("statsys_10yr.csv", subdir = TRUE)
df_statsys <- 
  vroom(file = "data/statsys_10yr.csv",
        delim = ";",
        col_types = cols(`SDG description` = col_character()),
        num_threads = 1) |>
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
