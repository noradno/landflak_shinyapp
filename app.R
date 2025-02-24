# Shiny web app for å generere og laste ned parametriserte landflak i wordformat ----
# Skrevet av Einar Tornes
# Appen publseres via Rstudio desktop eller Rstudio Cloaud til shinyapps.io-serveren: https://noradstats.shinyapps.io/landflak/

# Appens server kjører scriptet landflak.Rmd når bruker har valgt landparameter på nettsiden (ui)

# Pakken noradstats må reinstalleres ved ny last til shinyapps.io: devtools::install_github("noradno/noradstats")
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

# Laster inn data i global environment ved å source scriptet import_data.R ---
source("import_data.R")

# Country list for user input
select_country <- df_oda_ten |>
  filter(type_of_flow == "ODA") |>
  filter(type_of_agreement != "Rammeavtale") |>
  filter(income_category != "Unspecified") |>
  filter(year == max(year)) |>
  group_by(recipient_country_no_visual) |>
  summarise(total = sum(disbursed_mill_nok)) |>
  ungroup() |>
  filter(total > 0) |>
  filter(!is.na(recipient_country_no_visual)) |>
  select(recipient_country_no_visual) |>
  arrange() |>
  pull()


# Shiny app ----

# Spesifiserer frontend ----
ui <-
    fluidPage(
        
        # Tema
        #theme = shinythemes::shinytheme("cerulean"),
        
        # Overskrift
        titlePanel(title = "Landflak - bistand til enkeltland"),
        
        # Landvalg i nedtrekksmeny
        fluidRow(
            column(6, # kolonnebredde (6 er halv skjermbredde)
            selectInput("select_country",
                        label = "Velg land",
                        choices = select_country),
            
            # Nedlastingsknapp
            downloadButton("report", "Generer landflak i Microsoft Word-format"),
            
            # Animasjon når serveren jobber
            add_busy_spinner(spin = "semipolar", position = "full-page")
            )),
        
        # Tekstomtale
        fluidRow(
            column(12, # kolonnebredde (6 er halv skjermbredde)
                   p(), br(),
                   includeMarkdown("ui_tekst.md"), # Tekstfil med info til brukere
                   p(), br(),
                   img(src = "norad_logo_black_small_rgb_micro.png")
            )
        )
    )

# Innlogging med brukernavn og passord: wrapper ui i secure_app()
ui <- secure_app(ui,
                 theme = "cerulean",
                 set_labels(
                   language = "en",
                   "Login" = "Logg inn",
                   "Please authenticate" = "Vennligst logg inn",
                   "Username:" = "Brukernavn",
                   "Password:" = "Passord"),
                 tags_bottom = tags$div(
                   tags$p("Ved spørsmål om innlogging, kontakt ",
                          tags$a(
                            href = "mailto:norad-statistikk.og.analyse@norad.no",
                            target="_top", "Seksjon for Statistikk og analyse")),
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
