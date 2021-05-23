# Shiny web app med med nedlastbare parametriserte landflak om norsk bistand til mottakerland

### Beskrivelse av funksjonalitet

Appen er publisert som en nettside på følgende URL: <https://noradstats.shinyapps.io/landflak/>

Basert på brukervalgt land genereres og et landflak i word-format, som lastes ned.

Landflakene sammenstiller offisiell statistikk på øremerket bistand til enkeltland, fra Norge og andre medlemsland i OECDs utviklingskomite (DAC). I tillegg presenteres offisielle beregninger fra OECD på hvor mye av Norges multilaterale kjernestøtte som brukes på mottakerlandet.

Bruker kan velge blant land som mottok bistand fra Norge ved forrige rapporteringsår.

Landflakene er i word-format, og er basert på en spesiallaget word-mal med norad-logo.

Appen bygges i scriptet app.R, som spesifiserer både ui (front-end) og server (back-end).

### Info ved oppdatering

-   Appen baseres på flere datakilder, som importeres fra mappen data. Legg inn nye datafiler i data-mappen og slett gamle datafiler. Vær oppmerksom på riktige filnavn og variabelnavn.
-   Oppdater alle pakker før opplasting til shinyapps.io. Viktig å reinnstallere pakken noradstats via devtools::install_github("einartornes/noradstats"). Det skyldes at noradstats har dependencies til en rekke andre pakker, og gir feilmelding uten reinnstallasjon.
-   Appen publiseres via Rstudio til shinyapps.io på følgende URL: <https://noradstats.shinyapps.io/landflak/>

### Beskrivelse av filer

#### Script

-   app.R: Shiny appen bygges med scriptet. Spesifiserer funksjonalitet i ui (front-end) og server (back-end):

    -   ui (front-end): spesifiserer nettsiden inkl. brukerinput fra landliste (parameter) og action-button.
    -   server (back-end): kjører scriptet landflak.Rmd for valgte land (parameter) når bruker trykker action-button, og laster ned filen.

-   import_data.R: Laster inn data fra mappen data/. Sriptet sources (kjøres) i app.R

-   landflak.Rmd: Dette er selve landflaket. Parametrisert landflak i word-format som bygges basert på brukervalgt land. Scriptet kjøres i server-spesifiseringen i app.R når bruker har valgt land og trykker på action button.

#### Datafiler

-   data/ (mappe): inneholder følgende datafiler:

    -   statsys_10yr.csv: norsk bistandsstatistikk i csv-format. Kilde: pakken noradstats devtools::install_github("einartornes/noradstats")
    -   oecd_dac_donors.xlsx: øremerket bistand fra medlemsland i OECD DAC siste rapporteringsår, avgrenset til enkeltland som har mottatt øremerket bistand fra Norge. Kilde: OECDs statistikkdatabase (CRS).
    -   imputed_multi_land.xlsx: Beregnet norsk multilateral kjernestøtte til mottakerland siste ti år, avgrenset til land som har mottatt øremerket bistand fra Norge de ti aktuelle årene Kilde: OECDs statistikkdatabase (DAC2a).
    -   imputed_multil_land_org.xlsx: Beregnet norsk multilateral kjernestøtte til mottakerland per organisasjon siste år, avgrenset til land som har mottatt øremerket bistand fra Norge det aktuelle året . Kilde: Tilsendes fra OECD DCD over epost.
    -   land_og_regioner.xlsx: Bro-tabell med visuelle landnavn tilsvarende bistandsresultater.no, for å kunne linke til aktuell landside i bistandsresultater. Kilde: land_og_regioner.xlsx fra siste datalast til bistandsresultater.no

#### Andre filer og mapper

-   ui_tekst.md: Tekst som beskriver portalen i front-end (ui). Sources inn i ui-spesifiseringen i app.R

-   README.md: en beskrivelsen av appens funksjonalitet og komponenter

-   template/ (mappe): inneholder word-mal:

    -   landflak_template_logo.docx: en spesialtilpassed word-mal til landflak med norad-logo.

-   www/ (mappe): inneholder logoer i ulik størrelse:

    -   norad_logo_black_small_rgb.png: brukes i landflak.Rmd
    -   norad_logo_black_small_rgb_micro.png: brukes front-end (både innlogging og på nettsiden).
