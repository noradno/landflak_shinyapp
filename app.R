# Shiny web app for å generere og laste ned parametriserte landflak i wordformat ----
# Skrevet av Einar Tornes
# Appen er publisert publisert på shinyapps.io med innlogging: https://noradstats.shinyapps.io/landflak/

# Appens server kjører scriptet landflak.Rmd når bruker har valgt landparameter på nettsiden (ui)
# Datagrunnalg: Datafiler legges i mappen data/ før opplasting til shinyapps.io. Data lastes inn i app.r med scriptet import_data.R
# Pakken noradstats må reinstalleres ved ny last til shinyapps.io: devtools::install_github("einartornes/noradstats")

# Laster inn pakker ----
library(shiny)
library(shinybusy)
library(shinymanager)
library(shinythemes)
library(vroom)
library(dplyr)

# Laster inn data i global environment ved å source scriptet import_data.R
source("import_data.R")

# Landliste til ui: bruker-input (land-parameter) ----
select_country <- df_statsys %>%
  filter(type_of_flow == "ODA") |>
  filter(type_of_agreement != "Rammeavtale") |>
  filter(income_category != "Unspecified") |>
  filter(year == max(year)) |>
  group_by(recipient_country_no) |>
  summarise(total = sum(disbursed_mill_nok)) |>
  filter(total > 0) |>
  select(recipient_country_no) |>
  arrange() |>
  pull()
  
# Shiny app ----

# Spesifiserer frontend ----
ui <-
    fluidPage(
        
        # Tema
        theme = shinytheme("cerulean"),
        
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
            column(12
                   , # kolonnebredde (6 er halv skjermbredde)
                   p(), br(),
                   includeMarkdown("ui_tekst.md"), # Tekstfil med info til brukere
                   p(), br(),
                   "Sist oppdatert: ", Sys.Date(),
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
                            href = "mailto:post-stat@norad.no",
                            target="_top", "post-stat@norad.no")),
                   tags$img(src = "norad_logo_black_small_rgb_micro.png")
                   )
                 )

# Spesifiserer backend ----
server <- function(input, output) {
    
    # Passordbeskyttelse: Sjekker credentials for å godkjenne innlogging
    res_auth <- secure_server(
        check_credentials = check_credentials(data.frame(
            user = c("norad", "landflak123", "landflak"),
            password = c("norad", "landflak123", "landflak321"),
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
