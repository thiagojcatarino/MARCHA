# ================================
# PROJECT: MLPD
# LEAD:    GUSTAVO PINTO
# SCRIPT:  GROUP BALANCE 
# AUTHOR:  THIAGO CATARINO
# AIM:     Estimating Electoral Variations to causal effect of LPG 
# NOTES:   Run after ‘heterogeneity_estimation’ has generated 'estimacao_heterogeneidade_", SCOPE, ".RData'
# ================================
# 1: - Total execution time: 1 min

# ENVIRONMENT SETUP ------------------------------------------------------------

if (!exists("DIR.OUTPUT.PROJECT")) {
  source("config.R")
}

if (!"groundhog" %in% loadedNamespaces()) {
  source("groundhog_init.R")
}
# ===============================================================
# CULTURE DATA 
# ===============================================================

# Loading Culture Data
if (
  exists("siconfi_cultura") && exists("lpg_cultura") &&
  exists("rais_cultura") && exists("pib_municipal") &&
  exists("ideb_educ") && exists("superior_educ") &&
  exists("eleitoral_cultura")
) {
  cat("✅ Culture databases already available in the environment. Skipping load.\n")
} else if (
  file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("dados_", SCOPE, ".RData")
    )
  )
) {
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("dados_", SCOPE, ".RData")
    )
  )
  cat(
    sprintf(
      "✅ Databases loaded successfully from 'dados_%s.RData'.\n",
      SCOPE
    )
  )
} else {
  stop(
    sprintf(
      "⚠️ File 'dados_%s.RData' not found. Please run build.R first.",
      SCOPE
    )
  )
}

# Loading Culture Panel
if (
  exists("panel") &&
  is.data.frame(panel)
) {
  cat("✅ Culture panel already available in the environment. Skipping load.\n")
} else if (
  file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("painel_", SCOPE, ".RData")
    )
  )
) {
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("painel_", SCOPE, ".RData")
    )
  )
  cat(
    sprintf(
      "✅ Culture panel loaded successfully from 'painel_%s.RData'.\n",
      SCOPE
    )
  )
} else {
  stop(
    sprintf(
      "⚠️ File 'painel_%s.RData' not found. Please run group_balance.R first.",
      SCOPE
    )
  )
}

# # Regression Data
if (!exists("score_lpg")) {
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("estimacao_heterogeneidade_", SCOPE, ".RData")
    )
  )
  cat(
    sprintf(
      "✅ Heterogeneity estimation data loaded successfully from 'estimacao_heterogeneidade_%s.RData'.\n",
      SCOPE
    )
  )
}

# ===============================================================
# ELECTED MAYORS (2020)
# ---------------------------------------------------------------
# Keep only elected mayors and merge LPG treatment outcomes.
#
# WARNING:
# Before using slice_max(), check whether municipalities are
# actually duplicated after filtering elected mayors:
#
# prefeitos_2020 %>%
#   count(cod_ibge) %>%
#   filter(n > 1)
#
# If the result returns 0 rows, then slice_max() is unnecessary
# and may be safely removed.
#
# The need for slice_max() usually arises because of
# supplementary elections, where a municipality may have more
# than one elected mayor associated with the same election year.
# In that case, the most recent election date is retained.
# ===============================================================

eleitoral_cultura <- eleitoral_cultura %>%
  rename(
    cod_ibge = id_municipio,
    year     = ano
  ) %>%
  mutate(
    cod_ibge = as.integer(cod_ibge),
    year     = as.integer(year)
  ) %>%
  filter(
    cargo == "prefeito",
    resultado == "eleito",
    !is.na(cod_ibge)
  ) %>%
  group_by(cod_ibge, year) %>%
  slice_max(
    data_eleicao,
    n = 1,
    with_ties = FALSE
  ) %>%
  ungroup()

# ===============================================================
# LPG + ELECTORAL PANEL
# ---------------------------------------------------------------
# Match elected mayors (2020) with LPG execution outcomes.
# ===============================================================

prefeitos_2020 <- eleitoral_cultura %>%
  filter(year == 2020) %>%
  left_join(
    panel %>%
      filter(year == 2023) %>%
      select(
        cod_ibge,
        lpg_group,
        lpg_exec_rate
      ) %>%
      distinct(),
    by = "cod_ibge"
  )


# sigla_partido column in score_lpg data frame

score_lpg <- score_lpg %>%
  select(-any_of("sigla_partido"))

score_lpg <- score_lpg %>%
  left_join(
    prefeitos_2020 %>%
      select(
        cod_ibge,
        sigla_partido
      ),
    by = "cod_ibge"
  )


score_lpg <- score_lpg %>%
  mutate(
    espectro_pol = case_when(
      
      # Esquerda
      sigla_partido %in% c(
        "PT",
        "PC do B", "PSOL", "PDT",
        "PSB"
      ) ~ "Esquerda",
      
      # Centro
      sigla_partido %in% c(
        "REDE",
        "CIDADANIA",
        "PV"
      ) ~ "Centro",
      
      # Direita
      sigla_partido %in% c(
        "MDB",
        "PSD",
        "PSDB",
        "PODE",
        "PRTB",
        "PROS",
        "REPUBLICANOS",
        "PL",
        "PTC",
        "PSL",
        "DC",
        "NOVO",
        "PP",
        "PSC",
        "PTB",
        "AVANTE",
        "SOLIDARIEDADE",
        "PMN",
        "PMB",
        "PATRIOTA",
        "DEM"
      ) ~ "Direita",
      
      TRUE ~ NA_character_
    )
  )


# --------------------------------------------------
# 10. Political Economy Regression 
# --------------------------------------------------

# Division along the political spectrum
mod_espectro_pol <- feols(
  
  score ~
    perc_superior_educ +
    pib_pc +
    culture_exp_pc +
    pop +
    espectro_pol,
  
  data = score_lpg
)

summary(mod_espectro_pol)


# Municipalities governed by left-wing parties have, 
# on average, a score that is approximately 3.1 percentage points 
# higher than municipalities governed by centrist parties.

# The data do not support the claim that right-leaning 
# municipalities implemented the LPG less effectively 
# than centrist municipalities.

# Left Wing > Centrist - YES
# Left Wing > Right Wing - maybe


# --------------------------------------------------
# Saving
# --------------------------------------------------

# Save with estimations 
save(
  score_lpg,
  mod_superior_educ,
  mods_regionais,
  mods_estaduais,
  mod_espectro_pol,
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0(
      "estimacao_heterogeneidade_",
      SCOPE,
      ".RData"
    )
  )
)


# Save with fig built data
save(
  did_lpg,
  did_treat_map,
  mod_did_links,
  mod_did_wage,
  mod_score,
  mod_superior_educ,
  mods_regionais,
  mods_estaduais,
  mod_espectro_pol,
  panel,
  score_lpg,
  diagnostics,
  siconfi_cultura,
  lpg_cultura,
  rais_cultura,
  pib_municipal,
  ideb_educ,
  superior_educ,
  eleitoral_cultura,
  prefeitos_2020,
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0(
      "figuras_",
      SCOPE,
      ".RData"
    )
  )
)

message(
  paste0(
    "✅ Object 'figuras_",
    SCOPE,
    ".RData' saved."
  )
)


