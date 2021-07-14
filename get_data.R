# Scriptet laster ned datakilder som brukes i appen fra noradstats google drive
# Scriptet sources inn i scriptet app.R, og trenger dermed ikke å kjøres separat
# Datakildene lastes ned til undermappen ./data

# Loading packages
library(googledrive)
library(purrr)

# Connecting to noradstats google drive
googledrive::drive_auth(email = "noradstats@gmail.com")

# Find available files
googledrive::drive_find()

# Selecting files to download
files <- c("oda_ten.csv",
           "oecd_dac_donors.xlsx",
           "land_og_regioner.xlsx",
           "imputed_multi_land_org.xlsx",
           "imputed_multi_land.xlsx")

# Filepath til undermappe ./data
paths <- paste0("data/", files)

# Create ./data-folder if not present.
if(file.exists("./data") == FALSE) {
  dir.create(file.path("./data"))
}

# Download selected files to subfolder ./data (using purrr::map2)
map2(.x = files, .y = paths, ~ googledrive::drive_download(file = .x,
                                                           path = .y,
                                                           overwrite = TRUE))