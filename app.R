
# Shiny web app som genererer parametrisert landrapport i word-format
# Appen kjører landflak.Rmd basert på brukervalgt land (parametrisert)
# Oppdateringer: Legg inn eventuelle oppdaterte datafiler i mappen data/ før opplasting til shinyapps.io
# Obs: Pakken noradstats må reinstalleres før hver opplasting til shinyapps.io: devtools::install_github("einartornes/noradstats")
# Koden er basert på følgende oppskrift: https://shiny.rstudio.com/articles/generating-reports.html

# Laster inn pakker ----
library(shiny)
library(shinybusy)
library(shinymanager)
library(shinythemes)
library(vroom)
library(dplyr)

# Landliste til bruker-input (land-parameter) ----
select_country <- 
    vroom(file = "data/statsys_10yr.csv",
          delim = ";",
          num_threads = 1, # Hindrer at spesialtegn lager nye rader
          .name_repair = janitor::make_clean_names,
          col_select = c(
              type_of_flow, type_of_agreement, income_category,
              year, recipient_country_no, disbursed_nok)) |>
  filter(type_of_flow == "ODA") |>
  filter(type_of_agreement != "Rammeavtale") |>
  filter(income_category != "Unspecified") |>
  filter(year == max(year)) |>
  group_by(recipient_country_no) |>
  summarise(total = sum(disbursed_nok)) |>
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
            column(6, # kolonnebredde (6 er halv skjermbredde)
                   p(), br(),
                   "Landflakene gir en kortfattet oversikt over Norges bistand til enkeltland.",
                   p(),
                   "Besøk også",
                   tags$a(href = "https://resultater.norad.no/no",
                          "bistandsresultater.no"),"for statistikk og resulater av norsk bistand",
                   p(),
                   "Ved spørsmål, ta kontakt med Statistikkseksjonen (post-stat@norad.no)",
                   p(), br(),
                   "Sist oppdatert: ", Sys.Date(),
                   p(), br(),
                   img(src = "norad_logo_black_small_rgb.png", width = "100px")
            )
        )
    )

# Innlogging med brukernavn og passord: wrapper ui i secure_app()
ui <- secure_app(ui, theme = "cerulean")

# Spesifiserer backend ----
server <- function(input, output) {
    
    # Passordbeskyttelse: Sjekker credentials for å godkjenne innlogging
    res_auth <- secure_server(
        check_credentials = check_credentials(data.frame(
            user = c("norad", "norad123", "landflak"),
            password = c("norad", "norad123", "landflak"),
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

shinyApp(ui, server)
