library(dplyr)
library(ggplot2)
library(forcats)
library(scales)
library(glue)
library(rlang)
library(noradstats)

run_bilateral_aid <- function(
    data_bilateral,
    selected_country,
    group_var,
    title = "Distribution",
    top_n = 5
) {
  # Helpers
  fmt_millnok <- function(x) {
    scales::number(x, accuracy = 0.1, decimal.mark = ",", big.mark = " ")
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
          paste0(" (", scales::percent(prosent, accuracy = 0.1, decimal.mark = ","), ")")
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
