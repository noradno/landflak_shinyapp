# Shiny web app for å laste ned landflak om norsk bistand til enkeltland

### Funksjonalitet

En Shiny web app som genererer og laster ned parametriserte rapporter i word-format basert på brukervalgt mottakerland.

Landflakene sammenstiller offisiell statistikk på øremerket bistand til enkeltland, fra Norge og andre medlemsland i OECDs utviklingskomite (DAC). I tillegg presenteres offisielle beregninger fra OECD på hvor mye av Norges multilaterale kjernestøtte som brukes på mottakerlandet. Landflakene dekker en tiårsperiode.

Bruker kan velge blant alle land som mottok øreemerket bistand ved forrige rapporteringsår.

Appen bygges med scriptet *app.R*, som spesifiserer både ui (front-end) og server (back-end).

Appen er publisert som en nettside på følgende URL: <https://noradstats.shinyapps.io/landflak/>

### Rutine ved oppdatering

-   Det er kun datakildene som trengs å oppdateres, og øvrige filer i appen kan være uendret. Legg inn nye datafiler i *data*/-mappen og slett gamle datafiler. Vær oppmerksom på riktige filnavn og variabelnavn.
-   Oppdater alle pakker før opplasting til *shinyapps.io*. Viktig å reinnstallere pakken noradstats via *devtools::install_github("einartornes/noradstats")*. Det skyldes at noradstats har dependencies til en rekke andre pakker, og gir feilmelding uten reinnstallasjon.
-   Appen publiseres via Rstudio til *shinyapps.io* på følgende URL: <https://noradstats.shinyapps.io/landflak/>

### Beskrivelse av filer

#### Script-filer

-   *app.R*: Scriptet bygger appen ved å spesifisere funksjonalitet i ui (front-end) og server (back-end):

    -   ui (front-end): spesifiserer nettsiden inkl. brukerinput fra landliste (parameter) og action-button (*Generer landflak i Microsoft Word-format*).
    -   server (back-end): kjører scriptet *landflak.Rmd* for valgte land (parameter) når bruker trykker action-button, og laster ned filen.

-   *import_data.R*: Script for å laste inn data fra mappen *data/*. Scriptet sources (kjøres) i scriptet *app.R*.

-   *landflak.Rmd*: Scriptet lager landflaket. Det er en parametrisert rapport i word-format med ett brukervalgt parameter: mottakerland. Scriptet kjøres i server-spesifiseringen i scriptet *app.R*, når bruker har valgt land og trykker på action button.

#### Datafiler

-   *data/* (mappe): inneholder følgende datafiler, som dekker ulike tidsrom.

    -   *statsys_10yr.csv*: Norsk bistandsstatistikk siste ti år i csv-format. Kilde: pakken noradstats devtools::install_github("einartornes/noradstats")
    -   *oecd_dac_donors.xlsx*: Øremerket bistand fra medlemsland i OECD DAC siste rapporteringsår, avgrenset til enkeltland som har mottatt øremerket bistand fra Norge. Kilde: OECDs statistikkdatabase (*CRS*).
    -   *imputed_multi_land.xlsx*: Beregnet norsk multilateral kjernestøtte til mottakerland siste ti år, avgrenset til land som har mottatt øremerket bistand fra Norge de ti aktuelle årene Kilde: OECDs statistikkdatabase (*DAC2a*).
    -   *imputed_multil_land_org.xlsx*: Beregnet norsk multilateral kjernestøtte til mottakerland per organisasjon siste år, avgrenset til land som har mottatt øremerket bistand fra Norge det aktuelle året . Kilde: Tilsendes fra OECD DCD over epost.
    -   *land_og_regioner.xlsx*: Bro-tabell med visuelle landnavn tilsvarende bistandsresultater.no, for å kunne linke til aktuell landside i bistandsresultater. Kilde: *land_og_regioner.xlsx* fra siste datalast til *bistandsresultater.no*

#### Andre filer og mapper

-   *ui_tekst.md*: Tekst som beskriver portalen i front-end (ui). Sources inn i ui-spesifiseringen i scriptet *app.R*

-   *README.md*: en beskrivelsen av appens funksjonalitet og komponenter

-   *template/* (mappe): inneholder word-mal til landflaket:

    -   *landflak_template_logo.docx*: en spesialtilpassed word-mal til landflak med norad-logo. Brukes i scriptet *landflak.Rmd*

-   *www/* (mappe): inneholder logoer i ulik størrelse:

    -   *norad_logo_black_small_rgb.png*: brukes i scriptet *landflak.Rmd*
    -   *norad_logo_black_small_rgb_micro.png*: brukes scriptet *app.R* front-end (både innlogging og på nettsiden).
