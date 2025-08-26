#' Summarize and visualize total international bilateral aid to a selected country
#'
#' This function processes OECD/DAC bilateral aid data to summarize and visualize
#' which donor countries gave the most aid (in USD millions) to a selected recipient country
#' in the most recent available year. It returns a ranked list of donors, the total amount received,
#' Norway's rank (if present), and a bar plot of the top 10 donors.
#'
#' @param data_int_raw A data frame of DAC bilateral ODA, produced by run_pipeline()
#'        Must include at least columns: `recipient_country_en_visual`, `oecd_donor_no`, `usd_mill`, and `year`.
#' @param selected_country A character string specifying the recipient country to analyze.
#'
#' @return A named list with:
#' \describe{
#'   \item{val_maxyear}{The most recent year of aid data}
#'   \item{val_total_usd}{Total aid (USD mill.) from all DAC donors to the selected country}
#'   \item{val_norway_rank}{String with Norway's donor rank (e.g., `"2nd"`) or `""` if not in data}
#'   \item{data_donors}{A tibble with all donors ranked by disbursements}
#'   \item{p_barplot}{A `ggplot2` bar plot of the top 10 donor countries}
#' }
#'
#' @examples
#' run_int_total_aid(data_int_raw = df_dac_raw, selected_country = "Malawi")
#'
#' @export

run_int_total_aid <- function(
    data_int_raw = df_dac_raw,
    selected_country = params$selected_country
) {
  # --- Helper: format USD values
  fmt_usdmill <- function(x, accuracy = 0.1) {
    scales::number(x, accuracy = accuracy, big.mark = " ", decimal.mark = ".")
  }
  
  # --- Prepare dataset
  prepare_int_data <- function(data, selected_country) {
    data |>
      filter(
        recipient_country_en_visual == selected_country,
        year == max(year)
      ) |>
      select(oecd_donor_no, usd_mill, year) |>
      arrange(desc(usd_mill)) |>
      mutate(
        val_number_rank = row_number(),
        val_rank_string = if_else(val_number_rank == 1, "", as.character(ordinal(val_number_rank)))
      )
  }
  
  # --- Plot
  make_plot_int_total <- function(data_top10, val_total_usd, selected_country, year) {
    label_text <- glue::glue(
      "DAC-countries Total: USD {fmt_usdmill(val_total_usd)} mill.\n",
      "Number of DAC-country donors: {nrow(data_int)}"
    )
    
    data_top10 |>
      mutate(oecd_donor_no = forcats::fct_reorder(oecd_donor_no, usd_mill)) |>
      ggplot(aes(x = oecd_donor_no, y = usd_mill)) +
      geom_col(fill = norad_pal("green")) +
      coord_flip(clip = "off") +
      scale_y_continuous(expand = expansion(c(0, 0.1))) +
      geom_text(
        aes(label = fmt_usdmill(usd_mill, accuracy = 1)),
        hjust = 0,
        nudge_y = 2
      ) +
      labs(
        title = glue("Largest donors to {selected_country} in {year}"),
        subtitle = "Bilateral ODA from OECD/DAC-countries. Net disbursed. USD mill.",
        x = NULL, y = NULL
      ) +
      annotate(
        "text", x = 1, y = Inf, hjust = 1, vjust = 0, size = 4,
        label = label_text
      ) +
      theme(
        axis.ticks.y = element_blank(),
        plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 12, margin = ggplot2::margin(t = 0, b = 5))
      )
  }
  
  # --- Main logic
  data_int <- prepare_int_data(data_int_raw, selected_country)
  
  val_maxyear <- max(data_int_raw$year)
  val_total_usd <- sum(data_int$usd_mill)
  val_norway_rank <- data_int |>
    filter(oecd_donor_no == "Norway") |>
    pull(val_rank_string)
  
  data_top10 <- data_int |> slice_max(usd_mill, n = 10)
  
  p_barplot <- make_plot_int_total(
    data_top10 = data_top10,
    val_total_usd = val_total_usd,
    selected_country = selected_country,
    year = val_maxyear
  )
  
  # --- Return
  list(
    val_maxyear = val_maxyear,
    val_total_usd = val_total_usd,
    val_norway_rank = val_norway_rank,
    data_donors = data_int,
    p_barplot = p_barplot
  )
}
