# Scriptet laster ned datakilder som brukes i appen fra noradstats google drive
# Scriptet sources inn i scriptet app.R, og trenger dermed ikke å kjøres separat
# Datakildene ned til undermappen ./data

# Laster inn nødvendige pakker
# Henter pakken noradstats fra github med devtools::install_github("einartornes/noradstats")

#install.packages("devtools")
#library(devtools)

#install_github("einartornes/noradstats")
library(noradstats)

#noradstats::find_aiddata()

# Download data files using funtion noradstats::download_aiddata

noradstats::download_aiddata("oda_ten.csv", subdir = TRUE)
noradstats::download_aiddata("oecd_dac_donors.xlsx", subdir = TRUE)
noradstats::download_aiddata("land_og_regioner.xlsx", subdir = TRUE)
noradstats::download_aiddata("imputed_multi_land_org.xlsx", subdir = TRUE)
noradstats::download_aiddata("imputed_multi_land.xlsx", subdir = TRUE)