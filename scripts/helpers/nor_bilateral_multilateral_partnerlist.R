#' Generate summary data and flextable of agreement partners for a selected country
#'
#' This function prepares a formatted table of the top agreement partners (or multilateral organizations)
#' providing aid to a selected recipient country in a given year.
#' The function supports both bilateral and multilateral aid datasets by allowing the grouping column
#' (`partner_col`) and the value column (`amount_col`) to be passed as arguments.
#'
#' The output includes:
#' - A flextable object for display in a Quarto report
#' - Top 3 partner labels with amounts, ready for use in narrative text
#' - A prefix (`"most of"` or `""`) depending on whether the aid is concentrated
#'
#' @param data A data frame with at least `year`, `recipient_country_en_visual`, a partner column and an amount column, produced by run_pipeline().
#' @param selected_country Character string with the name of the recipient country
#' @param maxyear Integer, most recent year to include (default: `max(data$year)`)
#' @param partner_col Unquoted column name (e.g. `agreement_partner`) indicating the grouping variable
#' @param amount_col Unquoted column name (e.g. `disbursed_mill_nok`) indicating the value to summarize
#' @param subtitle_label Optional string used in the table subtitle (default: `"aid"`)
#'
#' @return A list with the following elements:
#' \describe{
#'   \item{val_maxyear}{Integer, the year of the data used}
#'   \item{data_partnerlist}{A tibble of summarized aid by partner including an "Other" and "Total" row}
#'   \item{table_partnerlist}{A formatted `flextable` object}
#'   \item{val_top_labels}{Character string listing top 3 partners with values}
#'   \item{val_prefix}{Either `"most of"` or `""`, depending on concentration of aid}
#' }
#'
#' @examples
#' run_partnerlist(data = df_oda_ten, selected_country = "Malawi",
#'                 partner_col = agreement_partner,
#'                 amount_col = disbursed_mill_nok,
#'                 subtitle_label = "bilateral aid")
#'
#' @export

run_partnerlist <- function(
    data,
    selected_country = params$selected_country,
    maxyear = max(data$year),
    partner_col,
    amount_col,
    subtitle_label = "aid"
) {
  
  # -- Helpers --
  fmt_millnok <- function(x) {
    scales::number(x, accuracy = 0.1, decimal.mark = ",", big.mark = " ")
  }
  
  # -- Prepare summarized partner list --
  prepare_partnerlist <- function(data, selected_country, maxyear, partner_col, amount_col) {
    partner_sym <- rlang::ensym(partner_col)
    amount_sym <- rlang::ensym(amount_col)
    
    data <- data |>
      filter(
        recipient_country_en_visual == selected_country,
        year == maxyear
      ) |>
      group_by({{ partner_col }}) |>
      summarise(mill_nok = sum({{ amount_col }}, na.rm = TRUE), .groups = "drop") |>
      arrange(desc(mill_nok))
    
    data_top <- data |> slice_max(mill_nok, n = 10)
    
    data_rest <- data |>
      filter(!({{ partner_col }} %in% data_top[[rlang::as_string(partner_sym)]])) |>
      summarise(mill_nok = sum(mill_nok)) |>
      mutate({{ partner_col }} := "Other") |>
      relocate({{ partner_col }}, mill_nok)
    
    data_combined <- bind_rows(data_top, data_rest) |>
      filter(mill_nok != 0)
    
    bind_rows(
      data_combined,
      tibble(
        !!partner_sym := "Total",
        mill_nok = sum(data_combined$mill_nok)
      )
    )
  }
  
  # -- Create flextable output --
  make_flextable_partnerlist <- function(data_partnerlist, partner_col, selected_country, maxyear, subtitle_label) {
    black_border <- officer::fp_border(color = "black")
    
    data_flex <- data_partnerlist |>
      mutate(`NOK mill` = fmt_millnok(mill_nok)) |>
      select("Agreement partner" = {{ partner_col }}, `NOK mill`)
    
    flextable(data_flex) |>
      align(align = "left", j = 1, part = "all") |>
      align(align = "right", j = 2, part = "all") |>
      border_remove() |>
      hline_bottom(border = black_border, part = "header") |>
      hline(border = black_border, part = "body", i = nrow(data_flex) - 1) |>
      set_table_properties(width = 1, layout = "autofit") |>
      height_all(0.25, part = "all") |>
      hrule(rule = "exact", part = "all") |>
      add_header_lines(
        paste("Agreement Partners,", subtitle_label, "to", selected_country, "in", maxyear)
      ) |>
      font(fontname = "Cambria", part = "all") |>
      fontsize(size = 9, part = "all") |>
      fontsize(size = 11, part = "header") |>
      bold(part = "header", i = 1) |> 
      bold(part = "body", i = nrow(data_flex))
  }
  
  # -- Extract top 3 labels and prefix --
  make_top3_text <- function(data_partnerlist, partner_col) {
    partner_col_str <- rlang::as_name(rlang::ensym(partner_col))
    
    data_txt <- data_partnerlist |> filter(!.data[[partner_col_str]] %in% c("Total", "Other"))
    n_partners <- nrow(data_txt)
    
    val_top_labels <- data_txt |>
      arrange(desc(mill_nok)) |>
      head(3) |>
      mutate(label = glue::glue(
        "{.data[[partner_col_str]]} (NOK {fmt_millnok(mill_nok)} mill)"
      )) |>
      pull(label) |>
      glue::glue_collapse(sep = ", ", last = " and ")
    
    val_prefix <- if_else(
      dplyr::n_distinct(data_txt[[partner_col_str]]) <= 3,
      "",
      "most of"
    )
    
    list(
      val_top_labels = val_top_labels,
      val_prefix = val_prefix
    )
  }
  
  # -- Main logic --
  data_partnerlist <- prepare_partnerlist(data, selected_country, maxyear, {{ partner_col }}, {{ amount_col }})
  table_partnerlist <- make_flextable_partnerlist(data_partnerlist, {{ partner_col }}, selected_country, maxyear, subtitle_label)
  top_text <- make_top3_text(data_partnerlist, {{ partner_col }})
  
  # -- Return outputs --
  list(
    val_maxyear = maxyear,
    data_partnerlist = data_partnerlist,
    table_partnerlist = table_partnerlist,
    val_top_labels = top_text$val_top_labels,
    val_prefix = top_text$val_prefix
  )
}
