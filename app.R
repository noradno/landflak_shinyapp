# Shiny app for generating and downloading Quarto-based country snapshot reports (Word format) ----
# 
# Production app URL: https://noradstats.shinyapps.io/country-snapshot
# Development app URL: https://noradstats.shinyapps.io/country-snapshot-dev
#
# Before deploying the app:
# - Follow steps in README.md to update data sources
# - Ensure the Word template is present in the /template/ folder
# - Quarto CLI must be installed and available on system PATH

# Load packages ----
library(shiny)
library(shinybusy)
library(shinymanager)
library(shinythemes)
library(dplyr)
library(markdown)
library(config)
library(bslib)
library(quarto)
library(withr)
library(here)
library(readr)

# Load list of available countries used in dropdown menu
df_countries <- read_rds(here("data", "final", "df_countries.rds"))

select_country <- df_countries |> 
  select(recipient_country_en_visual) |> 
  pull()

# Shiny UI ----
ui <- page_sidebar(
  title = "Country snapshots – Statistical overviews of Norwegian development aid (ODA) to recipient countries",
  sidebar = sidebar(
    title = NULL,
    open = "always",
    width = "300px",
    selectInput(
      "select_country", 
      label = "Select country",
      choices = select_country
    ),
    downloadButton("report", "Produce"),
    add_busy_bar()
  ),
  card(style = "max-width: 1000px",
       card_header("Produce Country Snapshots"),
       includeMarkdown("ui_text.md")
  )
)

# Secure login wrapper
ui <- secure_app(ui,
                 theme = "cerulean",
                 set_labels(language = "en"),
                 tags_bottom = tags$div(
                   tags$p("For questions, please contact ",
                          tags$a(
                            href = "mailto:norad-statistikk.og.analyse@norad.no",
                            target="_top", "Norad's Section for Statistics and Analysis")),
                   tags$img(src = "norad_logo_black_small_rgb_micro.png")
                 )
)

# Shiny Server ----
server <- function(input, output) {
  
  # Authenticate user
  res_auth <- secure_server(
    check_credentials = check_credentials(data.frame(
      user = config::get("credentials")$user,
      password = config::get("credentials")$password,
      stringsAsFactors = FALSE
    ))
  )
  
  # Report rendering and download
  output$report <- downloadHandler(
    filename = function() {
      paste0(input$select_country, "-snapshot.docx")
    },
    content = function(file) {
      temp_dir <- tempdir()
      output_name <- "report.docx"
      
      # Render the Quarto report in a temp dir
      tryCatch({
        withr::with_dir(temp_dir, {
          system2("quarto", c(
            "render", here::here("country_snapshot.qmd"),
            "--output", output_name,
            "--execute-param", paste0("selected_country=", input$select_country)
          ))
        })
        
        file.copy(file.path(temp_dir, output_name), file, overwrite = TRUE)
        
      }, error = function(e) {
        showNotification("Failed to generate report. Check template and logs.", type = "error")
        stop(e)
      })
    }
  )
}

# Launch app ----
shinyApp(ui, server)
