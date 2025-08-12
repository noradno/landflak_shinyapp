#' Generate summary data and bar plot of Norwegian bilateral aid to a selected country by agreement partner type or target area
#'
#' This function filters and aggregates Norwegian bilateral aid data (`data_bilateral`) for a single
#' recipient country and groups the aid by a user-specified variable — either agreement partner type or target area.
#' It returns a bar chart, top categories, and summary statistics for use in parameterized Quarto reports.
#'
#' @param data_bilateral A data frame of cleaned bilateral aid data, produced by run_pipeline()
#' @param selected_country Character. Name of the recipient country (must match values in `recipient_country_en_visual`)
#' @param group_var Character. Name of the grouping variable; must be either `"agreement_partner"` or `"target_area"`
#' @param title Character. Title for the plot (default: `"Distribution"`)
#' @param top_n Integer. Number of top categories to show before aggregating remainder into "Other" (default: `5`)
#'
#' @return A named list with:
#' \describe{
#'   \item{val_maxyear}{The latest year in `data_bilateral`}
#'   \item{data_grouped}{A tibble of bilateral disbursements by group (with amounts and percentages)}
#'   \item{p_barplot}{A `ggplot` bar chart of bilateral aid by group}
#'   \item{val_top_labels}{A comma-separated summary of the top 3 groups, formatted with NOK values}
#'   \item{val_prefix}{A short phrase, either `"most of"` or `""`, used in summary sentences}
#' }
#'
#' @examples
#' run_bilateral_aid(df_oda_ten, selected_country = "Uganda", group_var = "target_area")
#' run_bilateral_aid(df_oda_ten, selected_country = "Malawi", group_var = "agreement_partner")
#'
#' @export

run_bilateral_aid <- function(
    data_bilateral,
    selected_country,
    group_var,
    title = "Distribution",
    top_n = 5
) {
  # Helpers
  fmt_millnok <- function(x) {
    scales::number(x, accuracy = 1, decimal.mark = ",", big.mark = " ")
  }
  
  group_sym <- rlang::sym(group_var)
  group_sym_str <- rlang::as_string(group_sym)
  
  # Prepare data
  data_grouped <- data_bilateral |>
    filter(
      recipient_country_en_visual == selected_country,
      year == max(year)
    ) |>
    group_by(!!group_sym) |>
    summarise(mill_nok = sum(disbursed_mill_nok), .groups = "drop") |>
    mutate(prosent = mill_nok / sum(mill_nok)) |>
    arrange(desc(mill_nok)) |>
    mutate(rank = row_number())
  
  if (nrow(data_grouped) > (top_n + 1)) {
    data_grouped <- data_grouped |>
      mutate(!!group_sym := if_else(
        rank > top_n,
        "Other",
        as.character(!!group_sym)
      )) |>
      group_by(!!group_sym) |>
      summarise(
        mill_nok = sum(mill_nok),
        prosent = sum(prosent),
        .groups = "drop"
      )
  }
  
  data_grouped <- data_grouped |>
    mutate(!!group_sym := fct_reorder(!!group_sym, mill_nok, .desc = FALSE))
  
  if ("Other" %in% levels(data_grouped[[group_var]])) {
    data_grouped <- data_grouped |>
      mutate(!!group_sym := fct_relevel(!!group_sym, "Other", after = 0))
  }
  
  has_negative_prosent <- any(data_grouped$prosent < 0)
  
  # Plot
  p_barplot <- ggplot(data_grouped, aes(x = !!group_sym, y = mill_nok)) +
    geom_col(width = 0.8, fill = norad_pal("green")) +
    coord_flip() +
    scale_y_continuous(expand = expansion(c(0, 0.4))) +
    geom_text(
      aes(label = paste0(
        fmt_millnok(mill_nok),
        if (!has_negative_prosent) {
          paste0(" (", scales::percent(prosent, accuracy = 1, decimal.mark = ","), ")")
        } else {
          ""
        }
      )),
      hjust = 0,
      nudge_y = 2
    ) +
    labs(
      title = title,
      subtitle = paste0(
        "Bilateral aid to ",
        selected_country,
        " in ",
        max(data_bilateral$year),
        ". NOK million"
      ),
      x = NULL, y = NULL
    ) +
    theme(
      plot.title = element_text(size = 16),
      plot.subtitle = element_text(size = 12, margin = ggplot2::margin(t = 0, b = 5)),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.line.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.line.y = element_blank()
    )
  
  # Top 3 labels
  val_top_labels <- data_grouped |>
    arrange(desc(mill_nok)) |>
    head(3) |>
    mutate(label = glue("{.data[[group_sym_str]]} (NOK {fmt_millnok(mill_nok)} mill)")) |>
    pull(label) |>
    glue::glue_collapse(sep = ", ", last = " and ")
  
  # Prefix
  val_prefix <- if_else(
    dplyr::n_distinct(data_grouped[[group_var]]) <= 3,
    "",
    "most of"
  )
  
  # Return
  list(
    val_maxyear = max(data_bilateral$year),
    data_grouped = data_grouped,
    p_barplot = p_barplot,
    val_top_labels = val_top_labels,
    val_prefix = val_prefix
  )
}
