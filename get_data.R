# Download data files from noradstats google drive and stre in subfolder ./data

# Get noradstats-package from github using devtools:install_github(einartornes/noradstats")

#install.packages("devtools")
#library(devtools)

#install_github("einartornes/noradstats")
library(noradstats)

#noradstats::find_aiddata()

noradstats::download_aiddata("oda_ten.csv", subdir = TRUE)
noradstats::download_aiddata("oecd_dac_donors.xlsx", subdir = TRUE)
noradstats::download_aiddata("land_og_regioner.xlsx", subdir = TRUE)
noradstats::download_aiddata("imputed_multi_land_org.xlsx", subdir = TRUE)
noradstats::download_aiddata("imputed_multi_land.xlsx", subdir = TRUE)