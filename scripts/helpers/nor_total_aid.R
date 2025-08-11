#' Summarize and visualize total Norwegian aid to a selected country by aid type
#'
#' This function prepares and visualizes Norwegian Official Development Assistance (ODA)
#' to a selected recipient country, combining both bilateral aid (direct disbursements)
#' and imputed multilateral core support. The result is a stacked bar plot showing
#' annual totals by aid type, with total labels and values formatted in NOK millions.
#'
#' @param data_nor_bilateral_raw A data frame of bilateral disbursements from Statsys, produced by run_pipeline().
#'        Must include `recipient_country_en_visual`, `disbursed_mill_nok`, and `year`.
#' @param data_nor_multilateral_raw A data frame of imputed multilateral aid to countries, produced by run_pipeline().
#'        Must include `recipient_country_en_visual`, `disbursed_mill_nok`, and `year`.
#' @param selected_country A character string with the name of the recipient country to visualize.
#'
#' @return A named list with:
#' \describe{
#'   \item{val_bilateral_maxyear}{Most recent year of bilateral aid}
#'   \item{val_bilateral_maxyear_sum}{Formatted NOK amount for bilateral aid in most recent year}
#'   \item{val_multilateral_maxyear}{Most recent year of multilateral aid}
#'   \item{val_multilateral_maxyear_sum}{Formatted NOK amount for multilateral aid in most recent year}
#'   \item{p_total_aid}{A stacked `ggplot2` bar chart of total aid by year and aid type}
#' }
#'
#' @examples
#' run_nor_total_aid(
#'   data_nor_bilateral_raw = df_oda_ten,
#'   data_nor_multilateral_raw = df_imp_raw,
#'   selected_country = "Mozambique"
#' )
#'
#' @export

run_nor_total_aid <- function(
    data_nor_bilateral_raw = df_oda_ten,
    data_nor_multilateral_raw = df_imp_raw,
    selected_country = params$selected_country
) {
  # -- Helpers --
  
  prepare_bilateral <- function(data, country) {
    data |>
      filter(
        recipient_country_en_visual == country,
        year >= max(year) - 9
      ) |>
      group_by(year) |>
      summarise(mill_nok = sum(disbursed_mill_nok), .groups = "drop") |>
      mutate(type_bistand = "Bilateral aid", .before = 1) |>
      complete(
        year = seq(min(year), max(year)),
        fill = list(type_bistand = "Bilateral aid", mill_nok = 0)
      )
  }
  
  prepare_multilateral <- function(data, country, years) {
    data |>
      filter(
        recipient_country_en_visual == country,
        year %in% years
      ) |>
      transmute(
        type_bistand = "Estimated multilateral core support",
        year = as.numeric(year),
        mill_nok = disbursed_mill_nok
      )
  }
  
  make_plot <- function(data, country, years) {
    data |>
      mutate(type_bistand = fct_rev(type_bistand)) |>
      ggplot(aes(x = year, y = mill_nok, fill = type_bistand)) +
      geom_col(position = "stack") +
      geom_text(
        aes(label = scales::label_number(accuracy = 1, big.mark = " ")(mill_nok), colour = type_bistand),
        position = position_stack(vjust = 0.5), show.legend = FALSE
      ) +
      stat_summary(
        data = data |> group_by(year) |> filter(n_distinct(type_bistand) > 1),
        fun = sum,
        aes(
          x = year,
          y = mill_nok,
          label = after_stat(scales::label_number(accuracy = 1, big.mark = " ")(y))
        ),
        geom = "text", vjust = -1, inherit.aes = FALSE
      ) +
      scale_fill_manual(values = c("#b4eac9", "#03542d")) +
      scale_colour_manual(values = c("black", "white")) +
      scale_y_continuous(expand = expansion(c(0, 0.2))) +
      scale_x_continuous(breaks = seq(min(years), max(years), by = 1)) +
      coord_cartesian(clip = "off") +
      labs(
        title = paste0("Norwegian Aid to ", country, ", by Type of support"),
        subtitle = paste0(min(years), "-", max(years), " NOK million."),
        x = NULL, y = NULL
      ) +
      theme(
        plot.title = element_text(size = 16),
        axis.text.x = element_text(size = 11),
        legend.position = "bottom",
        legend.title = element_blank(),
        legend.text = element_text(size = 11),
        legend.key.size = unit(0.3, "cm"),
        axis.ticks.x = element_blank()
      ) +
      guides(fill = guide_legend(reverse = TRUE), colour = guide_legend(reverse = TRUE))
  }
  
  # -- Main logic --
  
  data_bilateral <- prepare_bilateral(data_nor_bilateral_raw, selected_country)
  all_years <- data_bilateral$year
  data_multilateral <- prepare_multilateral(data_nor_multilateral_raw, selected_country, all_years)
  
  data_total <- bind_rows(data_bilateral, data_multilateral)
  
  val_bilateral_maxyear <- max(data_bilateral$year)
  val_multilateral_maxyear <- max(data_multilateral$year)
  
  val_bilateral_maxyear_sum <- data_bilateral |>
    filter(year == val_bilateral_maxyear) |>
    pull(mill_nok) |>
    scales::number(accuracy = 0.1, decimal.mark = ",", big.mark = " ")
  
  val_multilateral_maxyear_sum <- data_multilateral |>
    filter(year == val_multilateral_maxyear) |>
    pull(mill_nok) |>
    scales::number(accuracy = 0.1, decimal.mark = ",", big.mark = " ")
  
  p_total_aid <- make_plot(data_total, selected_country, all_years)
  
  # -- Return outputs --
  list(
    val_bilateral_maxyear = val_bilateral_maxyear,
    val_bilateral_maxyear_sum = val_bilateral_maxyear_sum,
    val_multilateral_maxyear = val_multilateral_maxyear,
    val_multilateral_maxyear_sum = val_multilateral_maxyear_sum,
    p_total_aid = p_total_aid
  )
}
