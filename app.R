# Shiny web app for å generere og laste ned parametriserte landflak i wordformat ----
# Skrevet av Einar Tornes
# Appen publseres via Rstudio desktop eller Rstudio Cloaud til shinyapps.io-serveren: https://noradstats.shinyapps.io/landflak/

# Appens server kjører scriptet landflak.Rmd når bruker har valgt landparameter på nettsiden (ui)

# Pakken noradstats og noradplot må reinstalleres ved ny last til shinyapps.io: remotes::install_github("noradno/noradstats") og remotes::install_github("noradno/noradplot")
# Husk at alle filer skal inkluderes (inkl. word-template) når appen publiseres til shinyapps.io


# Før appen kjøres: last ned datakilder med separat script: get_data.R ---
# Scriptet get_data laster ned datafiler til mappen data/

# Laster inn pakker ----
library(shiny)
library(shinybusy)
library(shinymanager)
library(shinythemes)
library(dplyr)
library(markdown)
library(config)
library(bslib)

# Shiny app ----

# Load data
load(here::here("data_final", "countries.rda"))
load(here::here("data_final", "landflak_datasets.rda"))

select_country <- df_countries |> 
  select(recipient_country_en_visual) |> 
  pull()

# Spesifiserer frontend ----
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
        card_header("Information"),
        includeMarkdown("ui_tekst.md")
    )

)


# Innlogging med brukernavn og passord: wrapper ui i secure_app()
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

# Spesifiserer backend ----
server <- function(input, output) {
    
    # Passordbeskyttelse: Sjekker credentials for å godkjenne innlogging
    res_auth <- secure_server(
      check_credentials = check_credentials(data.frame(
        user = config::get("credentials")$user,
        password = config::get("credentials")$password,
        stringsAsFactors = FALSE))
    )
    
    output$report <- downloadHandler(
        
        # Lager docx-output med filnavn på valgte land
        filename = renderText({
            paste0(input$select_country, "_landflak.docx")
        }),
        content = function(file) {
            # Set up parameters to pass to Rmd document
            params <- list(land = input$select_country)
            
            # Knit the document, passing in the `params` list, and eval it in a
            # child of the global environment
            rmarkdown::render(
                "landflak.Rmd",
                output_file = file,
                params = params,
                envir = new.env(parent = globalenv())
            )
        }
    )
}

# Bygg app
shinyApp(ui, server)
