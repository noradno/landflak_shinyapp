# Landflakportal - en applikasjon for nedlastning av landflak om bistand til enkeltland

### Funksjonalitet

-   En Shiny web app som genererer og laster ned parametriserte rapporter i word-format basert på valgt mottakerland. Appen viser både øremerket bistand til enkeltland fra Norge og andre DAC-land, og beregnet multilateral kjernestøtte fra Norge til enkeltland. Appen har dermed mer info enn hva som inngår i norsk offisiell bistandsstatistikk, og skal presentere bistanden i et kort flak.
-   Appen er for internt bruk og krever derfor brukernavn og passord.
-   Landflakene sammenstiller offisiell statistikk på øremerket bistand til enkeltland, fra Norge og andre medlemsland i OECDs utviklingskomite (DAC). I tillegg presenteres offisielle beregninger fra OECD på hvor mye av Norges multilaterale kjernestøtte som brukes på mottakerlandet. Landflakene dekker en tiårsperiode.
-   Bruker kan velge blant alle land som mottok øreemerket bistand ved forrige rapporteringsår.
-   Appen bygges med scriptet *app.R*, som spesifiserer både ui (front-end) og server (back-end).
-   Appen publiseres på en nettside på følgende URL: <https://noradstats.shinyapps.io/landflak/>. I tillegg er dev-portal og test-portal på følgende URL: <https://noradstats.shinyapps.io/landflak-dev/> <https://noradstats.shinyapps.io/landflak-test/>
-   Appen er versjonskontrollert, for å holde kontroll på versjon av R og pakkene.

### Rutine ved oppdatering av datakilder

1.  Oppdater datafilene i mappen data_raw_and_processed/raw. Slett gamle filversjoner, slik at det ikke er flere filer med samme navn.
2.  Kjør scriptet *01_get_data_donors.R* for å hente data fra OECDs API på DAC-lands ODA til enkeltland. Lagres automatisk som csv i mappen data_raw_and_processed/processed. Husk å oppdater årstall for årgang i starten av scriptet for at nyeste data skal hentes.
3.  Kjør scriptet *02_get_data_imputed.R* for å hente data fra OECDs API på Norsk beregnet imputert kjernestøtte til enkeltland. Lagres automatisk som csv i mappen data_raw_and_processed/processed. Husk å oppdater årstall for årgang i starten av scriptet for at nyeste data skal hentes.
4.  Kjør scriptet *03_create_final_data.R* for å hente offisielle norsk bistandstatistikk for bistand til enkeltland og bearbeide alle datakilder til bruk i landflaket. Resultatet er 5 data frames som lagres i 1 rda-fil i mappen data_final.
5.  Oppdater alle pakker og R-versjonen før opplasting til *shinyapps.io*. Viktig å av- og reinnstallere pakkene noradstats og noradplots via *remotes::install_github("noradno/noradstats")* og *remotes::install_github("noradno/noradplot")*. Det skyldes at disse pakkene har dependencies til en rekke andre pakker, og gir feilmelding uten reinnstallasjon.
6.  Kjør scriptet *app.R* for å teste at den fungerer med oppdaterte datasett.
7.  Appen publiseres til *shinyapps.io* gjennom Rstudios *Publish the application or document* til følgende URL: <https://noradstats.shinyapps.io/landflak/>. Man velger hvilke filer som skal publiseres på shinyapps.io, og pass på at alle filer/mapper med viktig unntak av mappen data_raw_and_processed og eventuelle genererte word-dokumenter.
8.  Vanlige feilkilder ved publisering:
    -   Feil 1: Appen publiseres ikke: Appen publiseres ikke, dvs. man får en feilmelding når man går til <https://noradstats.shinyapps.io/landflak/>. Sjekk loggen for appen på shinyapps.io (noradstats@gmail.com er brukernavn). for å se hvor i koden det har gått galt. Typiske feil er at det er en pakke den ikke finner (og må legges inn med library(), eller at pakkene ikke er oppdaterte.

    -   Feil 2: Appen publiseres, slik at man kan logge inn i portalen, men når man genererer landflak, så får man ikke word-filer, men filer som heter "report.html" og beskjed om at det var mislykket. Denne feilen er vanskeligere å identifisere hva skyldes, fordi det ikke fremgår av loggen på shinyapps.io. En typisk feil er at fila word-template-filen ikke er blitt med i opplastingen til shinyapps.io.

### Beskrivelse av filer

#### Script-filer

-   *app.R*: Scriptet bygger appen ved å spesifisere funksjonalitet i ui (front-end) og server (back-end):

    -   ui (front-end): spesifiserer nettsiden inkl. brukerinput fra landliste (parameter) og action-button (*Generer landflak i Microsoft Word-format*).
    -   server (back-end): kjører scriptet *landflak.Rmd* for valgte land (parameter) når bruker trykker action-button, og laster ned filen.

-   *01_get_data_donors.R:* Script for hente donordata fra OECDs API. Må kjøres før appen kjøres (app.R). Øremerket bistand fra medlemsland i OECD DAC siste rapporteringsår, avgrenset til enkeltland som har mottatt øremerket bistand fra Norge. Kilde: OECDs statistikkdatabase (*DAC2a*).

-   *02_get_data_imputed.R:* Script for hente imputed-data fra OECDs API. Må kjøres før appen kjøres (app.R). Beregnet norsk multilateral kjernestøtte til mottakerland siste ti år, avgrenset til land som har mottatt øremerket bistand fra Norge de ti aktuelle årene Kilde: OECDs statistikkdatabase (*DAC2a*). Scriptet henter også vekslingskurs fra USD-NOK for å få norske beløp på beregningene.

-   *03_create_final_data.R*: Script for å hente offisiell norsk bistandstatistikk for bistand til enkeltland og bearbeide alle datakilder til bruk i landflaket. Scriptet inkluderer også landnavn-kolonnen *recipient_country_no_visual* i alle datafilene, som er de visuelle landnavnene tilsvarende i bistandsresultater.no. Resultatet er 5 data frames som lagres i 1 rda-fil i mappen data_final.

-   *landflak.Rmd*: Scriptet genererer landflaket. Det er en parametrisert rapport i word-format med ett brukervalgt parameter: mottakerland. Scriptet kjøres i server-spesifiseringen i scriptet *app.R*, når bruker har valgt land og trykker på action button "Generer landflak i Microsoft Word-format" i appen.

#### Datafiler
Til info: Grunnen til at data_raw_and_processd og data_final er i to separate mapper i project directory er at det er enklere å velge hvilke datafiler som skal inkluderes ved publisering til shinyapps.io, for kun filene i data_final skal deployes dit.

-   Datafiler legges inn i mappen data_raw_and_processed/raw. Datafilene dekker ulike tidsrom og er basert på ulike datakilder.
    -   *land_og_regioner.csv*: Bro-tabell med visuelle landnavn tilsvarende bistandsresultater.no, for å kunne linke til aktuell landside i bistandsresultater. Kilde: *land_og_regioner.xlsx* fra siste datalast til *bistandsresultater.no*. Denne brukes også ved datalast til bistandsresultater.no, så bruk den samme fila her.
    -   *exchangerate.csv*: Vekslingskurser USD-NOK tilgjengelig på excelfil hos OECD: [Development finance data - OECD](https://www.oecd.org/dac/financing-sustainable-development/development-finance-data/): <https://www.oecd.org/dac/financing-sustainable-development/development-finance-data/Exchange-rates.xls> Vi kan ikke bruke OECDs offisielle vekslingskurser i deres database-API, men istedet bruke bistandsrelevante vekslingskurser herfra som låses i april hvert år.
    -   *crs_donors_code.csv*: En liste med to kolonner: crs_donors_code og iso_code. Vi trenger iso_code for donorland fordi iso_code brukes i OECDs APIer i scriptene 01_get_data_donors.R og 02_get_data_imputed.R. Datakilde er [OECDs kodeoversikt](https://web-archive.oecd.org/temp/2024-06-19/57753-dacandcrscodelists.htm) 
    -   *crs_recipients_code.csv*: En liste med to kolonner: crs_recipients_code og iso_code. Vi trenger iso_code for mottakerland fordi iso_code brukes i OECDs APIer i scriptene 01_get_data_donors.R og 02_get_data_imputed.R. Datakilde er [OECDs kodeoversikt](https://web-archive.oecd.org/temp/2024-06-19/57753-dacandcrscodelists.htm) 

#### Andre filer og mapper

-   *ui_tekst.md*: Tekst som beskriver portalen i front-end (ui). Sources inn i ui-spesifiseringen i scriptet *app.R*

-   *README.md*: en beskrivelsen av appens funksjonalitet og komponenter

-   *template/* (mappe): inneholder word-mal til landflaket:

    -   *landflak_template_logo.docx*: en spesialtilpassed word-mal til landflak med norad-logo. Brukes i scriptet *landflak.Rmd*

-   *www/* (mappe): inneholder logoer i ulik størrelse:

    -   *norad_logo_black_small_rgb.png*: brukes i scriptet *landflak.Rmd*
    -   *norad_logo_black_small_rgb_micro.png*: brukes scriptet *app.R* front-end (både innlogging og på nettsiden).
