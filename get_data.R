# Scriptet laster ned datakilder som brukes i appen fra noradstats google drive
# Datakildene lastes ned til undermappen ./data

# Loading packages
library(googledrive)
library(purrr)
library(noradstats)

# Connecting to noradstats google drive
googledrive::drive_auth(email = "noradstats@gmail.com")

# Find available files
googledrive::drive_find()

# Selecting files to download
files <- c("land_og_regioner.csv",
           "imputed_multi_land_org.csv",
           "exchangerate.csv")

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
