# IBGE_functions

# ---------------------------------
# List of municipalities (IBGE) to be used as id_ente
# ---------------------------------
# The id_ente in SICONFI corresponds to the IBGE code of the state/municipality.
# Here we retrieve ALL municipalities directly from the IBGE Localities API.

get_municipios <- function() {
  url_ibge <- "https://servicodados.ibge.gov.br/api/v1/localidades/municipios"
  res <- GET(url_ibge, timeout(60))
  stop_for_status(res)
  j <- fromJSON(content(res, as = "text", encoding = "UTF-8"), flatten = TRUE)
  
  # j$id = IBGE code for the municipality  (7 digits)
  tibble::tibble(
    mun_cod  = as.integer(j$id),
    mun_nome = j$nome,
    uf_sigla = j$microrregiao.mesorregiao.UF.sigla,
    uf_cod   = as.integer(j$microrregiao.mesorregiao.UF.id)
  ) %>%
    arrange(uf_sigla, mun_nome)
}





# ===============================================================
# 🧩 Function: fix_ibge()
# ---------------------------------------------------------------
# IBGE municipality codes always have 7 digits (e.g., 3304557).
# When we import spreadsheets, R usually reads these codes as numbers,
# removing leading zeros (e.g., “0520005” becomes 520005).
# This function:
#   1️⃣ Converts the code to text (using .character);
#   2️⃣ Ensures that all codes have exactly 7 digits;
#   3️⃣ Pads with leading zeros when they are missing.
# The result is a standardized identifier for joins and comparisons
# between databases (RAIS, SICONFI, LPG, etc.).
# ===============================================================

fix_ibge <- function(x) {
  x_chr <- trimws(as.character(x))
  x_chr[x_chr == ""] <- NA_character_
  stringr::str_pad(x_chr, width = 7, side = "left", pad = "0")
}



#  Normalization function for comparing city names
norm_name <- function(x) {
  x %>%
    str_squish() %>%
    str_to_lower() %>%
    stri_trans_general("Latin-ASCII") %>%     # remove acentos
    str_replace_all("[^a-z0-9 ]", " ") %>%    # tira pontuação
    str_squish()
}


# SICONFI_functions

# ---------------------------------
# Helpers
# ---------------------------------

# (0) ORDS Page (following "next" link)
fetch_rreo_all <- function(ano, bimestre, tipo, anexo, id_ente) {
  query <- list(
    an_exercicio = ano,
    nr_periodo = bimestre,
    co_tipo_demonstrativo = tipo,
    no_anexo = anexo,
    id_ente = id_ente
  )
  items_all <- list()
  next_url <- modify_url(url_base, query = query)
  
  repeat {
    res <- GET(next_url, timeout(60))
    stop_for_status(res)
    j <- fromJSON(content(res, as = "text", encoding = "UTF-8"), flatten = TRUE)
    
    if (!"items" %in% names(j)) break
    items_all[[length(items_all) + 1]] <- j$items
    
    # finding "next" link
    link_next <- NULL
    if ("links" %in% names(j) && is.data.frame(j$links)) {
      cand <- j$links[j$links$rel == "next", , drop = FALSE]
      if (nrow(cand) == 1 && nzchar(cand$href)) link_next <- cand$href
    }
    if (is.null(link_next)) break
    next_url <- link_next
  }
  
  if (length(items_all) == 0) return(tibble())
  dados <- bind_rows(items_all)
  names(dados) <- tolower(names(dados))  
  dados
}

# (1) Extracting prefix "estável" i cod_conta of Function 13 (Culture)
extract_prefix <- function(x) {
  # capturing till function[_-]*13" without digit 
  m <- str_match(x, "(?i)^(.*?funcao[_-]*13)(?!\\d)")
  m[, 2]
}

# (2) 1 municipality in 1 year -> total by collumn for culture
process_mun_ano <- function(mun_cod, ano) {
  dados <- fetch_rreo_all(ano, bimestre, tipo_demonstrativo, anexo, mun_cod)
  if (nrow(dados) == 0) {
    return(tibble(ano = integer(), mun_cod = integer(), coluna = character(), total = double()))
  }
  
  # basic check
  req_cols <- c("conta", "cod_conta", "coluna", "valor")
  if (!all(req_cols %in% names(dados))) {
    warning(sprintf("Mun %s ano %s: payload sem colunas esperadas (%s).",
                    mun_cod, ano, paste(setdiff(req_cols, names(dados)), collapse = ", ")))
    return(tibble(ano = integer(), mun_cod = integer(), coluna = character(), total = double()))
  }
  
  # isolating Culture's Function
  is_cultura_word <- grepl("\\bCULTURA\\b", dados$conta, ignore.case = TRUE, perl = TRUE)
  is_agricultura  <- grepl("\\bAGRICULTURA\\b", dados$conta, ignore.case = TRUE, perl = TRUE)
  is_cultura_func <- is_cultura_word & !is_agricultura
  
  func_rows <- dplyr::filter(dados, is_cultura_func)
  if (nrow(func_rows) == 0) {
    return(tibble(ano = ano, mun_cod = mun_cod, coluna = character(0), total = double(0)))
  }
  
  prefixes <- unique(na.omit(extract_prefix(func_rows$cod_conta)))
  
  if (length(prefixes) == 0) {
    base_mask   <- is_cultura_func
    func_mask   <- grepl("(?i)funcao[_-]*13(?!\\d)", dados$cod_conta, perl = TRUE)
    cultura_mask <- base_mask | func_mask
  } else {
    by_prefix <- Reduce(`|`, lapply(prefixes, function(p) {
      pat <- paste0("^", gsub("([\\W])", "\\\\\\1", p))  
      grepl(pat, dados$cod_conta, ignore.case = TRUE, perl = TRUE)
    }))
    cultura_mask <- by_prefix | is_cultura_func
  }
  
  dados_cultura <- dados[cultura_mask, , drop = FALSE]
  if (nrow(dados_cultura) == 0) {
    return(tibble(ano = ano, mun_cod = mun_cod, coluna = character(0), total = double(0)))
  }
  
  # aggregating total by column (in the culture field)
  totais <- dados_cultura %>%
    group_by(coluna) %>%
    summarise(total = sum(valor, na.rm = TRUE), .groups = "drop") %>%
    mutate(ano = ano, mun_cod = mun_cod) %>%
    select(ano, mun_cod, coluna, total)
  
  totais
}


# LPG_functions

# Helper to convert BRL-style numbers ("1.234,56") → numeric
brl_to_num <- function(x) {
  if (is.numeric(x)) return(x)
  x <- gsub("\\.", "", x)
  x <- gsub(",", ".", x)
  suppressWarnings(as.numeric(x))
}


# RAIS_functions

# helper for safe weighted average
# Safe weighted average:
# Uses n_vinculos as a weight to reflect the average wage per worker (not per municipality).
# Returns NA if all weights are zero or missing, to prevent incorrect divisions.

safe_wmean <- function(x, w) {
  w <- ifelse(is.na(w), 0, w)
  x <- ifelse(is.na(x), NA, x)
  if (sum(w, na.rm = TRUE) == 0) return(NA_real_)
  weighted.mean(x, w, na.rm = TRUE)
}




# ==========================================================
# HELPER FUNCTIONS TO FIG_BUILT
# ==========================================================

# grafico_lpg <- function(
#     data,
#     titulo,
#     subtitulo,
#     caption = "Fonte: Lei Paulo Gustavo e TSE"
# ) {
#   ggplot(
#     data,
#     aes(
#       x = reorder(grupo, valor),
#       y = valor
#     )
#   ) +
#     geom_col(
#       fill = cor_principal,
#       width = .92
#     ) +
#     coord_flip() +
#     geom_text(
#       aes(
#         label = paste0(
#           format(
#             round(valor, 1),
#             decimal.mark = ",",
#             nsmall = 1
#           ),
#           "%"
#         )
#       ),
#       hjust = 1.1,
#       color = "white",
#       size = 5
#     ) +
#     scale_y_continuous(
#       limits = c(0, 100),
#       labels = \(x) paste0(x, "%")
#     ) +
#     labs(
#       title = titulo,
#       subtitle = subtitulo,
#       caption = caption,
#       x = NULL,
#       y = NULL
#     ) +
#     tema_lpg
# }
# 
# grafico_lpg <- function(
#     data,
#     titulo,
#     subtitulo,
#     caption = "Fonte: Lei Paulo Gustavo e TSE"
# ) {
#   ggplot(
#     data,
#     aes(
#       x = reorder(grupo, valor),
#       y = valor
#     )
#   ) +
#     geom_col(
#       fill = cor_principal,
#       width = .92
#     ) +
#     coord_flip() +
#     geom_text(
#       aes(
#         label = paste0(
#           format(
#             round(valor, 1),
#             decimal.mark = ",",
#             nsmall = 1
#           ),
#           "%"
#         )
#       ),
#       hjust = -0.1,         # <- Joga o texto para fora (lado direito da barra)
#       color = cor_principal,# <- Muda para a cor principal para ficar visível no fundo branco
#       size = 5
#     ) +
#     scale_y_continuous(
#       labels = \(x) paste0(x, "%"),
#       expand = expansion(mult = c(0, 0.12)) # <- Adiciona uma margem extra na direita para o texto não cortar
#     ) +
#     labs(
#       title = titulo,
#       subtitle = subtitulo,
#       caption = caption,
#       x = NULL,
#       y = NULL
#     ) +
#     tema_lpg
# }
criar_indice <- function(
    data,
    grupo,
    variavel,
    ano_ini,
    ano_fim
) {

  municipios_grupo <- data %>%
    filter(
      lpg_group_merged == grupo
    ) %>%
    distinct(cod_ibge)

  data %>%

    filter(
      cod_ibge %in% municipios_grupo$cod_ibge,
      year >= ano_ini,
      year <= ano_fim
    ) %>%

    group_by(year) %>%

    summarise(
      valor = sum(
        {{ variavel }},
        na.rm = TRUE
      ),
      .groups = "drop"
    ) %>%

    mutate(
      index = valor / first(valor) * 100
    )
}

# 
# grafico_lpg <- function(
#     data,
#     titulo,
#     subtitulo,
#     caption = "Fonte: Lei Paulo Gustavo e TSE"
# ) {
#   ggplot(
#     data,
#     aes(
#       x = reorder(grupo, valor),
#       y = valor
#     )
#   ) +
#     geom_col(
#       fill = cor_principal,
#       width = .92
#     ) +
#     coord_flip() +
#     # ggrepel garante que os textos se ajustem ao espaço disponível sem cortar
#     ggrepel::geom_text_repel(
#       aes(
#         label = paste0(
#           format(
#             round(valor, 1),
#             decimal.mark = ",",
#             nsmall = 1
#           ),
#           "%"
#         )
#       ),
#       size = 5,
#       color = "black",            # Cor escura para ficar visível caso seja empurrado para fora
#       direction = "x",            # Move o texto apenas na horizontal (eixo do tamanho da barra)
#       box.padding = 0.2,          # Espaço mínimo ao redor do texto
#       point.padding = NA,
#       min.segment.length = 0,     # Desenha uma linha guia se o texto for empurrado muito longe
#       nudge_x = 0                 # Mantém o alinhamento no centro da barra correspondente
#     ) +
#     scale_y_continuous(
#       labels = \(x) paste0(x, "%"),
#       expand = expansion(mult = c(0, 0.15)) # Margem de segurança na direita para os textos empurrados
#     ) +
#     labs(
#       title = titulo,
#       subtitle = subtitulo,
#       caption = caption,
#       x = NULL,
#       y = NULL
#     ) +
#     tema_lpg
# }

# 
# 
# 
# grafico_lpg <- function(
#     data,
#     titulo,
#     subtitulo,
#     caption = "Fonte: Lei Paulo Gustavo e TSE"
# ) {
#   ggplot(
#     data,
#     aes(
#       x = reorder(grupo, valor),
#       y = valor
#     )
#   ) +
#     geom_col(
#       fill = cor_principal,
#       width = .92
#     ) +
#     coord_flip() +
#     ggrepel::geom_text_repel(
#       aes(
#         label = paste0(
#           format(
#             round(valor, 1),
#             decimal.mark = ",",
#             nsmall = 1
#           ),
#           "%"
#         )
#       ),
#       size = 5,
#       color = "black",
#       direction = "x",
#       box.padding = 0.2,
#       point.padding = NA,
#       segment.color = NA,          # <- ISSO REMOVE O SINAL DE MENOS / LINHA GUIA
#       min.segment.length = Inf     # <- Garante duplamente que nenhuma linha será desenhada
#     ) +
#     scale_y_continuous(
#       labels = \(x) paste0(x, "%"),
#       expand = expansion(mult = c(0, 0.15))
#     ) +
#     labs(
#       title = titulo,
#       subtitle = subtitulo,
#       caption = caption,
#       x = NULL,
#       y = NULL
#     ) +
#     tema_lpg
# }


grafico_lpg <- function(
    data,
    titulo,
    subtitulo,
    caption = "Fonte: Lei Paulo Gustavo e TSE"
) {
  ggplot(
    data,
    aes(
      x = reorder(grupo, valor),
      y = valor
    )
  ) +
    geom_col(
      fill = cor_principal,
      width = .92
    ) +
    coord_flip() +
    ggrepel::geom_text_repel(
      aes(
        label = paste0(
          format(
            round(valor, 1),
            decimal.mark = ",",
            nsmall = 1
          ),
          "%"
        )
      ),
      size = 5,
      color = "#E7B59F",            # <- Nova cor terracota clara com bom contraste
      direction = "x",
      box.padding = 0.2,
      point.padding = NA,
      segment.color = NA,          
      min.segment.length = Inf     
    ) +
    scale_y_continuous(
      labels = \(x) paste0(x, "%"),
      expand = expansion(mult = c(0, 0.15))
    ) +
    labs(
      title = titulo,
      subtitle = subtitulo,
      caption = caption,
      x = NULL,
      y = NULL
    ) +
    tema_lpg
}
########
grafico_indice_lpg <- function(
    dados,
    titulo,
    subtitulo,
    eixo_y = "Índice (2015 = 100)",
    fonte = "Fonte: RAIS/MTE"
) {
  
  ggplot(
    dados,
    aes(
      x = year,
      y = index,
      color = grupo,
      group = grupo
    )
  ) +
    
    geom_line(
      linewidth = 1
    ) +
    
    geom_point(
      size = 2
    ) +
    
    geom_vline(
      xintercept = 2023
    ) +
    
    scale_color_manual(
      values = c(
        "Alto Uso" = cor_escura,
        "Baixo Uso" = cor_secundaria
      )
    ) +
    
    labs(
      title = titulo,
      subtitle = subtitulo,
      x = "Ano",
      y = eixo_y,
      color = NULL,
      caption = fonte
    ) +
    
    tema_lpg
}

#######
tabela_top20_lpg <- function(data, titulo) {
  
  data %>%
    
    gt() %>%
    
    cols_label(
      ranking = "",
      muni_name = "Município",
      uf_abbrev = "UF",
      used_total = "Valor utilizado",
      used_pct = "% utilizado"
    ) %>%
    
    fmt_currency(
      columns = used_total,
      currency = "BRL",
      decimals = 0
    ) %>%
    
    fmt_percent(
      columns = used_pct,
      decimals = 1
    ) %>%
    
    data_color(
      columns = used_total,
      palette = c("white", cor_principal)
    ) %>%
    
    tab_header(
      title = titulo
    ) %>%
    
    tab_source_note(
      source_note = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC)"
    ) %>%
    
    tema_gt_descritiva()
}

#############

plot_high_use <- function(df, grupo, titulo) {
  
  dados <- df %>%
    filter(!is.na({{ grupo }})) %>%
    group_by({{ grupo }}) %>%
    summarise(
      prop_high = mean(lpg_group == "HIGH_USE"),
      .groups = "drop"
    ) %>%
    arrange(prop_high)
  
  ggplot(
    dados,
    aes(
      x = prop_high,
      y = reorder({{ grupo }}, prop_high)
    )
  ) +
    geom_point(size = 5) +
    scale_x_continuous(
      labels = scales::percent_format()
    ) +
    labs(
      title = titulo,
      x = "Proporção HIGH_USE",
      y = NULL
    ) +
    theme_minimal()
}


##############

calc_high_use <- function(df, grupo) {
  
  df %>%
    filter(!is.na(lpg_group)) %>%
    group_by({{ grupo }}) %>%
    summarise(
      municipios = n(),
      prop_high = mean(lpg_group == "HIGH_USE"),
      .groups = "drop"
    )
}

#################
calc_partido_regiao <- function(df, regiao_nome, min_municipios = 20) {
  
  df %>%
    filter(
      regiao == regiao_nome,
      !is.na(lpg_group)
    ) %>%
    group_by(sigla_partido) %>%
    summarise(
      municipios = n(),
      valor = 100 * mean(lpg_group == "HIGH_USE"),
      .groups = "drop"
    ) %>%
    filter(municipios >= min_municipios) %>%
    rename(grupo = sigla_partido)
}

################

dados_cnae <- function(data) {
  
  data %>%
    
    group_by(
      cnae_2_subclasse_descricao
    ) %>%
    
    summarise(
      valor = sum(
        n_vinculos,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) %>%
    
    mutate(
      valor = 100 * valor / sum(valor)
    ) %>%
    
    arrange(desc(valor)) %>%
    
    rename(
      grupo = cnae_2_subclasse_descricao
    )
}


# END OF SCRIPT ---------

