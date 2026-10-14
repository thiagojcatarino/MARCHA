# ================================
# PROJECT: MLPD
# LEAD:    GUSTAVO PINTO
# SCRIPT:  FIGURES BUILT 
# AUTHOR:  THIAGO CATARINO
# AIM:     Compile and generate all figures and tables used in the project
# NOTES:   Final reporting script. Runs after all data construction,
#          cleaning, matching, and estimation scripts have been completed.
#          Consolidates outputs and produces the complete set of figures,
#          tables, and descriptive results for analysis and reporting.
# ================================
# 1: - Total execution time: 5 min
#
# ENVIRONMENT SETUP ------------------------------------------------------------

if (!exists("DIR.OUTPUT.PROJECT")) {
  source("config.R")
}

if (!"groundhog" %in% loadedNamespaces()) {
  source("groundhog_init.R")
}

install.packages("ggrepel")
library(ggrepel)
library(scales)
# ==========================================================
# CULTURE DATA -----------------------------------------------------------

# Loading "figuras_", SCOPE, ".RData"
if (
  exists("siconfi_cultura") && exists("panel") &&
  exists("lpg_cultura") &&
  exists("mod_espectro_pol") && exists("prefeitos_2020")
) {
  cat("✅ Culture databases already available in the environment. Skipping load.\n")
} else if (
  file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("figuras_", SCOPE, ".RData")
    )
  )
) {
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("figuras_", SCOPE, ".RData")
    )
  )
  cat(
    sprintf(
      "✅ Databases loaded successfully from 'figuras_%s.RData'.\n",
      SCOPE
    )
  )
} else {
  stop(
    sprintf(
      "⚠️ File 'figuras_%s.RData' not found. Please run build.R first.",
      SCOPE
    )
  )
}
# DESCRIPTIVE FIGURES  
# ==========================================================
#     FIGURE 1 : Estados ------------------------------------------------------------

# Paulo Gustavo's Website Expenditures Data for States

dados <- tibble(
  estado = ordenar_ufs(ufs_brasil),

  valor = c(
    99.2,98.9,99.8,95.4,99.6,99.7,90.4,97.4,98.9,99.5,
    99.3,98.8,88.8,96.7,99.0,96.3,99.8,99.4,94.9,99.6,
    20.7,99.0,98.0,99.3,97.7,99.3,99.3
  )
)

# Organization
dados$estado <- factor(dados$estado, levels = rev(dados$estado))

fig_1 <- ggplot(dados, aes(x = estado, y = valor)) +
  geom_col(
    fill = "#B5654D",
    width = 0.9
  ) +
  coord_flip() +
  geom_text(
    aes(
      label = paste0(
        format(valor, decimal.mark = ",", nsmall = 1),
        "%"
      )
    ),
    hjust = 1.1,
    color = "#E7B59F",
    size = 5
  ) +
  scale_y_continuous(
    limits = c(0, 100),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title = "Estados",
    subtitle = "% dos gastos dos estados em relação ao recebido",
    caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC).",
    x = NULL,
    y = NULL
  ) +
  tema_lpg

fig_1

#     FIGURE 2 : Municípios ------------------------------------------------------------

# Paulo Gustavo's Website Expenditures Data - MUNICIPALITIES
# Dados do gráfico
dados <- tibble(
  estado = ordenar_ufs(ufs_brasil),
  
  valor = c(
    96.8,91.0,92.1,97.9,90.4,96.6,98.6,85.7,86.8,94.2,
    90.8,90.9,89.1,94.2,91.3,95.1,92.5,90.9,96.9,93.1,
    70.2,95.8,90.1,92.0,92.7,92.2,75.1
  )
)

fig_2 <- ggplot(dados, aes(x = estado, y = valor)) +
  
  geom_col(
    fill = cor_principal,
    width = .92
  ) +
  
  coord_flip() +
  
  geom_text(
    aes(
      label = paste0(
        format(
          valor,
          decimal.mark = ",",
          nsmall = 1
        ),
        "%"
      )
    ),
    hjust = 1.1,
    color = "#E7B59F",
    size = 5
  ) +
  
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    labels = \(x) paste0(x, ",0%")
  ) +
  
  labs(
    title = "Municípios",
    subtitle = "% dos gastos dos municípios em relação ao recebido",
    caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC).",
    x = NULL,
    y = NULL
  ) +
  
  tema_lpg

fig_2

#     TABLE 1  : Vinte municípios com maiores valores utilizados da Lei ------------------------------------------------------------

tab_1 <- lpg_cultura %>%
  
  group_by(
    cod_ibge,
    uf_abbrev,
    muni_name
  ) %>%
  
  summarise(
    transferred_total = sum(transferred_val, na.rm = TRUE),
    yield_total = sum(yield_val, na.rm = TRUE),
    used_total = sum(used_val_rs, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  
  mutate(
    used_pct = used_total / (transferred_total + yield_total)
  ) %>%
  
  arrange(desc(used_total)) %>%
  
  mutate(
    ranking = row_number()
  ) %>%
  
  slice(1:20)  

tab_1 <- tabela_top20_lpg(
  tab_1,
  "Vinte municípios com maiores valores utilizados da LPG"
)

tab_1

#     FIGURE 3 : Evolução do salário médio cultural: municípios com Alto Uso e Baixo Uso da Lei------------------------------------------------------------

criar_indice
plot_data %>%
  count(grupo)


panel %>%
  
  filter(
    lpg_group == "LOW_USE"
  ) %>%
  
  summarise(
    n = n(),
    anos = n_distinct(year)
  )

panel %>%
  
  filter(
    lpg_group == "LOW_USE"
  ) %>%
  
  summarise(
    miss_wage = mean(is.na(avg_culture_wage_bl))
  )



panel %>%
  
  filter(
    lpg_group == "LOW_USE"
  ) %>%
  
  summarise(
    municipios = n_distinct(cod_ibge),
    sem_baseline =
      mean(is.na(avg_culture_wage_bl))
  )
# CULTURE WAGE
h_pre_sum_index <- criar_indice(
  panel,
  "HIGH_USE",
  avg_culture_wage_bl,
  2015,
  2019
)

h_post_sum_index <- criar_indice(
  panel,
  "HIGH_USE",
  avg_culture_wage_bl,
  2022,
  2025
)

l_pre_sum_index <- criar_indice(
  panel,
  "LOW_USE",
  avg_culture_wage_bl,
  2015,
  2019
)

l_post_sum_index <- criar_indice(
  panel,
  "LOW_USE",
  avg_culture_wage_bl,
  2022,
  2025
)


# CULTURE WAGE - PLOT DATA


plot_data <- bind_rows(
  
  mutate(
    h_pre_sum_index,
    grupo = "Alto Uso"
  ),
  
  mutate(
    h_post_sum_index,
    grupo = "Alto Uso"
  ),
  
  mutate(
    l_pre_sum_index,
    grupo = "Baixo Uso"
  ),
  
  mutate(
    l_post_sum_index,
    grupo = "Baixo Uso"
  )
  
)

fig_3 <- grafico_indice_lpg(
  plot_data,
  "Rendimento Médio dos Empregos Culturais",
  "Municípios com Alto Uso vs Baixo Uso dos Recursos",
  fonte = "Fonte: RAIS/MTE; elaboração própria."
)

fig_3

#     FIGURE 4 : Evolução dos vínculos formais na cultura: municípios com Alto Uso e Baixo Uso da Lei------------------------------------------------------------

# CULTURE WORKERS 
h_pre_workers_index <- criar_indice(
  panel,
  "HIGH_USE",
  culture_workers,
  2015,
  2019
)

h_post_workers_index <- criar_indice(
  panel,
  "HIGH_USE",
  culture_workers,
  2022,
  2025
)

l_pre_workers_index <- criar_indice(
  panel,
  "LOW_USE",
  culture_workers,
  2015,
  2019
)

l_post_workers_index <- criar_indice(
  panel,
  "LOW_USE",
  culture_workers,
  2022,
  2025
)


# CULTURE WORKERS - PLOT DATA

plot_workers <- bind_rows(
  
  mutate(
    h_pre_workers_index,
    grupo = "Alto Uso"
  ),
  
  mutate(
    h_post_workers_index,
    grupo = "Alto Uso"
  ),
  
  mutate(
    l_pre_workers_index,
    grupo = "Baixo Uso"
  ),
  
  mutate(
    l_post_workers_index,
    grupo = "Baixo Uso"
  )
  
)

# Plots

fig_4 <- grafico_indice_lpg(
  plot_workers %>%
    filter(year < 2025),
  "Número de Vínculos Formais de Emprego Cultural",
  "Municípios com Alto Uso vs Baixo Uso dos Recursos",
  fonte = "Fonte: RAIS/MTE; elaboração própria."
)

fig_4
dados_cultura <- dados_cnae(
  rais_cultura
)

fig_4


#     FIGURE 5 : Participação dos CNAEs no Emprego Cultural: Todos os segmentos culturais ------------------------------

dados_cultura <- dados_cnae(
  rais_cultura
)

fig_5 <- grafico_lpg(
  dados_cultura,
  stringr::str_wrap("Participação dos CNAEs no Emprego Cultural", width = 30),
  stringr::str_wrap("Todos os segmentos culturais", width = 30),
  caption = stringr::str_wrap("Fonte: RAIS/MTE; elaboração própria.", width = 30)
) +
  theme(text = element_text(size = 12)) +
  scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 60)) +
  scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = 60))

fig_5

#     FIGURE 6 : Participação dos CNAEs no Emprego Cultural: Audiovisual ------------------------------


dados_audiovisual <- dados_cnae(
  rais_cultura %>%
    filter(
      cnae_2_subclasse %in% c(
        "5911101",
        "5911102",
        "5912001",
        "5912002",
        "5920100"
      )
    )
)

fig_6 <- grafico_lpg(
  dados_audiovisual,
  stringr::str_wrap("Participação dos CNAEs no Emprego Audiovisual", width = 30),
  stringr::str_wrap("Distribuição dos vínculos formais", width = 30),
  caption = stringr::str_wrap("Fonte: RAIS/MTE; elaboração própria.", width = 30)
) +
  theme(text = element_text(size = 12)) +
  scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 45)) +
  scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = 45))

fig_6



#     FIGURE 7 : Participação dos CNAEs no Emprego Cultural: Outras Artes ------------------------------

dados_outras_artes <- dados_cnae(
  rais_cultura %>%
    filter(
      !cnae_2_subclasse %in% c(
        "5911101",
        "5911102",
        "5912001",
        "5912002",
        "5920100"
      )
    )
)

fig_7 <- grafico_lpg(
  dados_outras_artes,
  stringr::str_wrap("Participação dos CNAEs em Outras Artes", width = 30),
  stringr::str_wrap("Distribuição dos vínculos formais", width = 30),
  caption = stringr::str_wrap("Fonte: RAIS/MTE; elaboração própria.", width = 30)
) +
  theme(text = element_text(size = 12)) +
  scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 45)) +
  scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = 45))

fig_7

# ==========================================================
# MAIN RESULTS
# ==========================================================
#     TABLE 2  : Tabela de Balanceamento --------------------------------------------------

tab_2 <- diagnostics$balance_table %>%
  
  mutate(
    
    HIGH_USE = if_else(
      variable == "pib_bl",
      HIGH_USE / 1e6,
      HIGH_USE
    ),
    
    LOW_NO_USE = if_else(
      variable == "pib_bl",
      LOW_NO_USE / 1e6,
      LOW_NO_USE
    ),
    
    diff = if_else(
      variable == "pib_bl",
      diff / 1e6,
      diff
    ),
    
    variable = recode(
      variable,
      avg_culture_wage_bl   = "Salário médio cultural",
      culture_exp_total_bl  = "Gasto público em cultura",
      pib_bl                = "PIB municipal (R$ milhões)",
      ideb_bl               = "IDEB"
    )
    
  ) %>%
  
  gt() %>%
  
  cols_label(
    variable    = "Variável",
    HIGH_USE    = "Alto Uso",
    LOW_NO_USE  = "Baixo/Nenhum Uso",
    diff        = "Diferença",
    pct_valid   = "% válido"
  ) %>%
  
  fmt_currency(
    columns = c(HIGH_USE, LOW_NO_USE, diff),
    rows = variable %in% c(
      "PIB municipal (R$ milhões)",
      "Gasto público em cultura",
      "Salário médio cultural"
    ),
    currency = "BRL",
    decimals = 2,
    locale = "pt_BR"
  ) %>%
  
  fmt_number(
    columns = c(HIGH_USE, LOW_NO_USE, diff),
    rows = !variable %in% c(
      "PIB municipal (R$ milhões)",
      "Gasto público em cultura",
      "Salário médio cultural"
    ),
    decimals = 2,
    locale = "pt_BR"
  ) %>%
  
  fmt_number(
    columns = pct_valid,
    decimals = 1,
    locale = "pt_BR"
  ) %>%
  
  cols_hide(
    c(
      n_valid,
      n_total
    )
  ) %>%
  
  tab_header(
    title = md(
      "**Características dos Municípios Antes da Implementação da LPG**"
    )
  ) %>%
  
  tab_source_note(
    source_note =
      "Fonte: RAIS, Siconfi, IBGE e elaboração própria."
  ) %>%
  
  tema_gt_descritiva()

tab_2

#     TABLE 3  : Resultados dos Modelos Principais: Diferenças-em-Diferenças  ------------------------------------------------------------

etable(
  mod_did_wage,
  mod_did_links,
  headers = c(
    paste0(
      "DiD: Renda Média do Emprego Cultural (RAIS)",
      scope_suffix
    ),
    paste0(
      "DiD: Número de Vínculos Formais (RAIS)",
      scope_suffix
    )
  ), 
  digits = 3,
  notes = c(
    "Fonte: RAIS/MTE; Censo Demográfico 2022 (IBGE); Siconfi/STN; elaboração própria"
  ),
  export = "png",
  
  file = file.path(
    DIR.TABLES,
    paste0("tab_3", SCOPE, ".png")
  ),
  view = TRUE
)



#     TABLE 3  : Resultados dos Modelos Principais: Determinantes do Score de Uso da LPG ------------------------------------------------------------

etable(
  mod_score,
  digits = 3,
  
  notes = c(
    "Fonte: RAIS/MTE; Censo Demográfico 2022 e PIB dos Municípios (IBGE)", 
    "Siconfi/STN; elaboração própria"
  ),
  export = "png",
  
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0("pt_lpg_mod2_", SCOPE, ".png")
  ),
  view = TRUE
)


# ==========================================================
# HETEROGENEITY
# ==========================================================
#     TABLE 5  : Resultados dos Modelos de Heterogeneidade: Determinantes do Alto  de Uso da LPG (Ensino Superior) ------------------------------------------------------------

etable(
  mod_superior_educ,
                          # using titles or not?
  # title = paste0( 
  #   "Determinantes do Status de Alta Execução da LPG",
  #   scope_suffix
  # ),
  tex = FALSE,
  digits = 4,
  se.below = TRUE,
  fitstat = ~ n + rmse + ar2,
  
  notes = c(
    "Fonte: RAIS/MTE; Censo Demográfico 2022 (IBGE)",
    "PIB dos Municípios (IBGE); Siconfi/STN; elaboração própria"
  ),
  
  export = "png",
  
  file = file.path(
    DIR.TABLES,
    paste0(
      "tab_5",
      SCOPE,
      ".png"
    )
  ),
  
  view = TRUE
)


#     TABLE 6  : Resultados dos Modelos de Heterogeneidade: Determinantes do Alto Uso da LPG - Macrorregiões ------------------------------------------------------------

etable( # Por Regiões com Concluintes do Ensino Superior em Municípios
  mods_regionais,
  
  headers = list(
    "Macrorregião" = names(mods_regionais)
  ),
  
  digits = 4,
  se.below = TRUE,
  signif.code = NA,
  
  fitstat = ~ n + rmse + ar2,
  
  notes = c(
    "Fonte: RAIS/MTE; Censo Demográfico 2022 e PIB dos Municípios (IBGE); Siconfi/STN; elaboração própria"
  ),
  
  export = "png",
  
  file = file.path(
    DIR.TABLES,
    paste0(
      "tab_6",
      SCOPE,
      ".png"
    )
  ),
  
  view = TRUE
)
# ==========================================================
# POLITICAL ECONOMY
# ==========================================================
#     FIGURE 8 : Distribuição dos Níveis de Uso da LPG por Partido ------------------------------------------------------------

fig_8 <- prefeitos_2020 %>%
  filter(!is.na(lpg_group)) %>%
  count(sigla_partido, lpg_group) %>%
  group_by(sigla_partido) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot(
    aes(
      x = reorder(sigla_partido, prop),
      y = prop,
      fill = lpg_group
    )
  ) +
  
  geom_col(width = .92) +
  
  coord_flip() +
  
  scale_fill_manual(
    values = c(
      "NO_USE" = "#F1E3DA",
      "LOW_USE" = "#E3B29B",
      "MEDIUM_USE" = "#C97B63",
      "HIGH_USE" = "#8B5E3C"
    )
  ) +
  
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1)
  ) +
  
  labs(
    title = "Distribuição dos Níveis de Uso da LPG por Partido",
    subtitle = "Participação relativa dos municípios em cada categoria de execução",
    caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC) e TSE; elaboração própria.",
    x = NULL,
    y = NULL,
    fill = NULL
  ) +
  
  theme_minimal(base_size = 18) +
  
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    
    legend.position = "bottom",
    
    plot.title = element_text(
      hjust = .5,
      face = "bold",
      size = 28
    ),
    
    plot.subtitle = element_text(
      hjust = .5,
      size = 18
    ),
    
    plot.caption = element_text(
      hjust = 0,
      face = "italic",
      size = 11
    )
  )

fig_8


#     FIGURE 9 : Distribuição dos Municípios por Nível de Utilização da LPG ---------------------------

cores_lpg <- c(
  "Fora da Política" = "#A8B5A2",
  "Nenhum Uso"       = "#F1E3DA",
  "Baixo Uso"        = "#E3B29B",
  "Médio Uso"        = "#C97B63",
  "Alto Uso"         = "#BA8563"
)

dados <- prefeitos_2020 %>%
  mutate(
    grupo = case_when(
      is.na(lpg_group) ~ "Fora da Política",
      lpg_group == "NO_USE" ~ "Nenhum Uso",
      lpg_group == "LOW_USE" ~ "Baixo Uso",
      lpg_group == "MEDIUM_USE" ~ "Médio Uso",
      lpg_group == "HIGH_USE" ~ "Alto Uso",
      TRUE ~ as.character(lpg_group)
    )
  )


principal <- dados %>%
  
  mutate(
    status = if_else(
      grupo == "Alto Uso",
      "Alto Uso",
      "Demais\nMunicípios"
    )
  ) %>%
  
  count(status) %>%
  
  mutate(
    perc = n / sum(n)
  ) %>%
  
  ggplot(
    aes(
      x = 1,
      y = perc,
      fill = status
    )
  ) +
  
  geom_col(
    width = 0.8,
    color = "#E7B59F",
    linewidth = 1
  ) +
  
  coord_flip() +
  
  geom_text(
    aes(
      label = paste0(
        status,
        "\n",
        percent(
          perc,
          accuracy = 0.1
        )
      )
    ),
    position = position_stack(
      vjust = 0.5
    ),
    color = "#E7B59F",
    fontface = "bold",
    family = fonte_lpg,
    lineheight = 0.9,
    size = 3.5
  ) +
  
  scale_fill_manual(
    values = c(
      "Demais\nMunicípios" = cor_principal,
      "Alto Uso" = cor_escura
    )
  ) +
  
  theme_void(
    base_family = fonte_lpg
  ) +
  
  theme(
    legend.position = "none"
  )

#

secundario <- dados %>%
  
  count(grupo) %>%
  
  mutate(
    perc_total = n / sum(n)
  ) %>%
  
  filter(
    grupo != "Alto Uso"
  ) %>%
  
  ggplot(
    aes(
      x = reorder(
        grupo,
        perc_total
      ),
      y = perc_total,
      fill = grupo
    )
  ) +
  
  geom_col(
    width = 0.7
  ) +
  
  coord_flip() +
  
  geom_text(
    aes(
      label = percent(
        perc_total,
        accuracy = 0.1
      )
    ),
    hjust = -0.15,
    family = fonte_lpg,
    fontface = "bold",
    size = 3
  ) +
  
  scale_fill_manual(
    values = cores_lpg
  ) +
  
  scale_y_continuous(
    labels = percent_format(),
    limits = c(0, 0.08),
    expand = expansion(
      mult = c(
        0,
        0.05
      )
    )
  ) +
  
  labs(
    title = "Destaque para Municípios Fora do Grupo de Alto Uso",
    x = NULL,
    y = NULL
  ) +
  
  tema_lpg +
  
  theme(
    
    legend.position = "none",
    
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    
    axis.text.y = element_text(
      family = fonte_lpg,
      face = "bold",
      size = 10
    ),
    
    axis.text.x = element_text(
      size = 9
    ),
    
    plot.title = element_text(
      face = "bold",
      size = 12,
      hjust = 0
    )
    
  )

# 

fig_9 <-
  
  principal /
  
  secundario +
  
  plot_layout(
    heights = c(
      1,
      2
    )
  ) +
  
  plot_annotation(
    
    title = "Distribuição dos Municípios por Nível de Utilização da LPG",
    caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC); elaboração própria.",
    
    theme = theme(
      
      plot.title = element_text(
        family = fonte_lpg,
        face = "bold",
        size = 14,
        hjust = 0.5
      ),
      
      plot.subtitle = element_text(
        family = fonte_lpg,
        size = 11,
        hjust = 0.5
      ),
      
      plot.caption = element_text(
        family = fonte_lpg,
        size = 9
      )
      
    )
    
  )

fig_9


#     TABLE 7  : Resultados dos Modelos de Economia Política: Determinantes do Score de Uso da LPG------------------------------------------------------------

etable(
  mod_espectro_pol,
  # TITLE??
  # title = paste0(
  #   "Resultados dos Modelos de Economia Política",
  #   scope_suffix
  # ),
  depvar = TRUE,
  fitstat = c("n", "ar2"),
  digits = 3,
  notes = c(
    "Fonte: TSE, RAIS, IBGE, Siconfi e elaboração própria."
  ),
  export = "png",
  file = file.path(
    DIR.TABLES,
    paste0(
      "pt_lpg_economia_politica_",
      SCOPE,
      ".png"
    )
  ),
  view = TRUE
)


#     FIGURE 10 : Municípios com Alto Uso da LPG: Percentuais de Uso por Partido ------------------------------------------------------------

plot_df <- prefeitos_2020 %>%
  filter(!is.na(lpg_group)) %>%
  group_by(sigla_partido) %>%
  summarise(
    municipios = n(),
    prop_high = mean(lpg_group == "HIGH_USE"),
    .groups = "drop"
  ) %>%
  filter(municipios >= 50) %>%
  arrange(prop_high)

media_brasil <- mean(
  prefeitos_2020$lpg_group == "HIGH_USE",
  na.rm = TRUE
)

fig_10 <- ggplot(
  plot_df,
  aes(
    x = prop_high * 100,
    y = reorder(sigla_partido, prop_high)
  )
) +
  
  # linha de referência nacional
  geom_vline(
    xintercept = media_brasil * 100,
    linetype = "dashed",
    linewidth = .8,
    color = "#8B5E3C"
  ) +
  
  # pontos
  geom_point(
    size = 5,
    color = "#C97B63"
  ) +
  
  # rótulos
  geom_text(
    aes(
      label = paste0(
        format(
          round(prop_high * 100, 1),
          decimal.mark = ",",
          nsmall = 1
        ),
        "%"
      )
    ),
    nudge_x = 2,
    size = 4.5,
    color = "#8B5E3C"
  ) +
  
  scale_x_continuous(
    limits = c(
      min(plot_df$prop_high * 100) - 5,
      max(plot_df$prop_high * 100) + 10
    )
  ) +
  
  labs(
    title = "Municípios com Alto Uso da LPG",
    subtitle = "Percentual de municípios com Alto Uso da LPG dentro de cada partido",
    caption = "Linha tracejada representa a média nacional. Fonte: Painel de Dados da Lei Paulo Gustavo (MinC) e TSE; elaboração própria.",
    x = NULL,
    y = NULL
  ) +
  
  theme_minimal(base_size = 18) +
  
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    
    plot.title = element_text(
      hjust = .5,
      face = "bold",
      size = 28
    ),
    
    plot.subtitle = element_text(
      hjust = .5,
      size = 18
    ),
    
    plot.caption = element_text(
      hjust = 0,
      face = "italic",
      size = 11
    )
  )

fig_10


#     FIGURE 11: Municípios com Alto Uso da LPG por Partido - Nordeste ------------------------------------------------------------

g_ne <- prefeitos_2020 %>%
  mutate(
    regiao = case_when(
      sigla_uf %in% c("AC","AP","AM","PA","RO","RR","TO") ~ "Norte",
      sigla_uf %in% c("AL","BA","CE","MA","PB","PE","PI","RN","SE") ~ "Nordeste",
      sigla_uf %in% c("DF","GO","MT","MS") ~ "Centro-Oeste",
      sigla_uf %in% c("ES","MG","RJ","SP") ~ "Sudeste",
      sigla_uf %in% c("PR","RS","SC") ~ "Sul"
    )
  )

dados_fig_11<- calc_partido_regiao(g_ne, "Nordeste")

fig_11 <-grafico_lpg(
  dados_fig_11,
  "Municípios com Alto Uso da LPG por Partido",
  "Nordeste",
  caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC) e TSE; elaboração própria."
)

fig_11


#     FIGURE 12: Municípios com Alto Uso da LPG por Partido - Sudeste ------------------------------------------------------------
g_se <- prefeitos_2020 %>%
  mutate(
    regiao = case_when(
      sigla_uf %in% c("AC","AP","AM","PA","RO","RR","TO") ~ "Norte",
      sigla_uf %in% c("AL","BA","CE","MA","PB","PE","PI","RN","SE") ~ "Nordeste",
      sigla_uf %in% c("DF","GO","MT","MS") ~ "Centro-Oeste",
      sigla_uf %in% c("ES","MG","RJ","SP") ~ "Sudeste",
      sigla_uf %in% c("PR","RS","SC") ~ "Sul"
    )
  )

dados_fig_12 <- calc_partido_regiao(g_se, "Sudeste")

fig_12 <- grafico_lpg(
  dados_fig_12,
  "Municípios com Alto Uso da LPG por Partido",
  "Sudeste",
  caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC) e TSE; elaboração própria."
)

fig_12

#     FIGURE 13: Municípios com Alto Uso da LPG por Partido - Rio de Janeiro ------------------------------------------------------------
g_rj <- prefeitos_2020

dados_fig_13 <- g_rj %>%
  filter(
    sigla_uf == "RJ",
    !is.na(lpg_group)
  ) %>%
  group_by(sigla_partido) %>%
  summarise(
    municipios = n(),
    valor = 100 * mean(lpg_group == "HIGH_USE"),
    .groups = "drop"
  ) %>%
  filter(municipios >= 2) %>%
  rename(grupo = sigla_partido)

fig_13 <- grafico_lpg(
  dados_fig_13,
  "Municípios com Alto Uso da LPG por Partido",
  "Estado do Rio de Janeiro",
  caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC) e TSE; elaboração própria."
)

fig_13
#     FIGURE 14: Municípios com Alto Uso da LPG por Partido - São Paulo -----------------------------------------------------------

g_sp <- prefeitos_2020
  
dados_fig_14 <- g_sp %>%
  filter(
    sigla_uf == "SP",
    !is.na(lpg_group)
  ) %>%
  group_by(sigla_partido) %>%
  summarise(
    municipios = n(),
    valor = 100 * mean(lpg_group == "HIGH_USE"),
    .groups = "drop"
  ) %>%
  filter(municipios >= 5) %>%
  rename(grupo = sigla_partido)

fig_14 <- grafico_lpg(
  dados_fig_14,
  "Municípios com Alto Uso da LPG por Partido",
  "Estado de São Paulo",
  caption = "Fonte: Painel de Dados da Lei Paulo Gustavo (MinC) e TSE; elaboração própria."
)

fig_14

# ==========================================================
# 6. TABLE EXPORTS
# ==========================================================
# GT Saves ---------------
tabelas_gt <- list(
  
  table_1 = tab_1,
  table_2 = tab_2
)

purrr::iwalk(
  tabelas_gt,
  ~ gtsave(
    .x,
    file.path(
      DIR.TABLES,
      paste0(.y, ".png")
    )
  )
)
# ==========================================================
# 7. SAVE FIGURES
# ==========================================================
# PNG Saves --------------------
figuras <- list(
  
  figure_01 = fig_1,
  figure_02 = fig_2,
  figure_03 = fig_3,
  figure_04 = fig_4,
  figure_05 = fig_5,
  figure_06 = fig_6,
  figure_07 = fig_7,
  figure_08 = fig_8,
  
  figure_09 = fig_9,
  
  figure_10 = fig_10,
  figure_11 = fig_11,
  figure_12 = fig_12,
  figure_13 = fig_13,
  figure_14 = fig_14
  
)

purrr::iwalk(
  figuras,
  ~ ggsave(
    filename = file.path(
      DIR.FIGURES,
      paste0(.y, ".png")
    ),
    plot = .x,
    width = 10,
    height = 6,
    dpi = 300,
    bg = "white"
  )
)

