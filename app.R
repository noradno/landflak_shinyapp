# Shiny web app to generate and download Quarto reports of Country snapshot of Norwegian in word format ----
# The prod app is published to shinyapps.io: https://noradstats.shinyapps.io/landflak/. Remember to include all files when deploying.
# Dev app is published to https://noradstats.shinyapps.io/landflak-dev/
# Procedure: Before deploying the app, follow the steps in README.md to update data sources.

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

# Load data sources
load(here::here("data_final", "countries.rda"))
load(here::here("data_final", "landflak_datasets.rda"))

# Load vector of unique countries
select_country <- df_countries |> 
  select(recipient_country_en_visual) |> 
  pull()

# Shiny app ----

# Front end ----
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
        includeMarkdown("ui-text.md")
    )

)


# Secure login, by wrapping ui in shinymanager::secure_app()
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

# Backend ----
server <- function(input, output) {
  
  # Secure login, checking credentials
  res_auth <- secure_server(
    check_credentials = check_credentials(data.frame(
      user = config::get("credentials")$user,
      password = config::get("credentials")$password,
      stringsAsFactors = FALSE))
  )
  
  output$report <- downloadHandler(
    filename = function() {
      paste0(input$select_country, "-snapshot.docx")
    },
    content = function(file) {
      temp_dir <- tempdir()
      output_name <- "report.docx"
      
      # Render the Quarto document in temp_dir (using system2 to use Quarto from CLI)
      withr::with_dir(temp_dir, {
        system2("quarto", c(
          "render", here::here("country_snapshot.qmd"),
          "--output", output_name,
          "--execute-param", paste0("selected_country=", input$select_country)
        ))
      })
      
      # Copy result to Shiny download location
      file.copy(file.path(temp_dir, output_name), file, overwrite = TRUE)
    }
  )
}

# Build app
shinyApp(ui, server)
