# ================================
# PROJECT: MLPD
# LEAD:    GUSTAVO PINTO
# SCRIPT:  ESTIMATION 
# AUTHOR:  THIAGO CATARINO
# AIM:     Estimating causal effect of LPG
# NOTES:   Run after ‘group_balance’ has generated 'matching_cultura.RData'
# ================================
# 1: - Total execution time: 1 min

# ENVIRONMENT SETUP ------------------------------------------------------------

if (!exists("DIR.OUTPUT.PROJECT")) {
  source("config.R")
}

if (!"groundhog" %in% loadedNamespaces()) {
  source("groundhog_init.R")
}

# CULTURE DATA -----------------------------------------------------------
if (
  exists("panel") &&
  inherits(panel, c("data.frame", "tbl_df"))
) {
  cat("✅ Object 'panel' already exists in the environment. Skipping load.\n")
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
      "✅ Analysis panel loaded successfully from 'painel_%s.RData'.\n",
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

# ===============================================================
# REGRESSION 1 — DIFFERENCES-IN-DIFFERENCES (DID)
# ---------------------------------------------------------------
# Treatment:
#   HIGH_USE municipalities in 2023 = 1
#   LOW_USE / MEDIUM_USE municipalities in 2023 = 0
#
# Pre-treatment period: 2015–2019
# Post-treatment period: 2023–2024
#
# Outcomes:
#   • Average cultural wage
#   • Number of cultural formal links
# ===============================================================


# Remove legacy treatment variable from previous exploratory models
# A new treatment definition will be created based on HIGH_USE in 2023

panel <- panel %>%
  select(-treated)


# Create final treatment assignment based on 2023 LPG execution
did_treat_map <- panel %>%
  filter(
    year == 2023,
    lpg_group %in% c(
      "LOW_USE",
      "MEDIUM_USE",
      "HIGH_USE"
    )
  ) %>%
  distinct(
    cod_ibge,
    lpg_group
  ) %>%
  mutate(
    did_treated =
      as.integer(
        lpg_group == "HIGH_USE"
      )
  )


# Build DiD sample
did_lpg <- panel %>%
  filter(
    year %in% c(2015:2019, 2023:2024)
  ) %>%
  left_join(
    did_treat_map %>%
      select(
        cod_ibge,
        did_treated
      ),
    by = "cod_ibge"
  ) %>%
  filter(
    !is.na(did_treated)
  ) %>%
  mutate(
    post = as.integer(year >= 2023),
    Trat = did_treated * post
  )


# Keep municipalities observed in both periods
keep_ids <- did_lpg %>%
  group_by(cod_ibge) %>%
  summarise(
    has_pre = any(post == 0),
    has_post = any(post == 1),
    .groups = "drop"
  ) %>%
  filter(
    has_pre & has_post
  ) %>%
  pull(cod_ibge)


did_lpg <- did_lpg %>%
  filter(
    cod_ibge %in% keep_ids
  )


# The class of culture_workers cannot be integer64.
# It must be converted to numeric before estimation.

panel <- panel %>%
  mutate(
    culture_workers =
      as.numeric(culture_workers)
  )


# ---------------------------------------------------------------
# DiD outcome 1: average cultural wage
# ---------------------------------------------------------------

mod_did_wage <- feols(
  avg_culture_wage ~ Trat |
    cod_ibge + year,
  cluster = ~ cod_ibge,
  data = did_lpg
)

summary(mod_did_wage)



# ---------------------------------------------------------------
# DiD outcome 2: number of cultural formal links
# ---------------------------------------------------------------

mod_did_links <- feols(
  culture_workers ~ Trat |
    cod_ibge + year,
  cluster = ~ cod_ibge,
  data = did_lpg
)

summary(mod_did_links)


# ===============================================================
# REGRESSION 2 — DETERMINANTS OF HIGH_USE SCORE
# ---------------------------------------------------------------
# Cross-sectional model using pre-treatment averages.
#
# Score:
#   HIGH_USE in 2023 = 1
#   Otherwise = 0
#
# Explanatory variables:
#   • IDEB
#   • Municipal GDP per capita
#   • Municipal cultural expenditure per capita
#   • Average cultural wage
#   • Number of cultural formal links
#   • Cultural employment share
# ===============================================================


# Build municipality-level baseline (pre-LPG)
score_lpg <- panel %>%
  filter(
    year %in% 2015:2019
  ) %>%
  group_by(cod_ibge) %>%
  summarise(
    
    ideb =
      mean(ideb, na.rm = TRUE),
    
    pib_pc =
      mean(pib_pc, na.rm = TRUE),
    
    culture_exp_pc =
      mean(
        culture_exp_total / pop,
        na.rm = TRUE
      ),
    
    salario_cultura =
      mean(
        avg_culture_wage,
        na.rm = TRUE
      ),
    
    n_vinculos_cultura =
      mean(
        culture_workers,
        na.rm = TRUE
      ),
    
    pop =
      mean(
        pop,
        na.rm = TRUE
      ),
    
    .groups = "drop"
  ) %>%
  left_join(
    did_treat_map %>%
      select(
        cod_ibge,
        did_treated
      ),
    by = "cod_ibge"
  ) %>%
  rename(
    score = did_treated
  )


# Estimate score model
mod_score <- feols(
  score ~
    ideb +
    pib_pc +
    culture_exp_pc +
    salario_cultura +
    n_vinculos_cultura +
    pop,
  data = score_lpg
)

summary(mod_score)



did_lpg %>%
  summarise(
    
    n_total = n(),
    
    wage_na =
      sum(
        is.na(avg_culture_wage)
      ),
    
    wage_na_pct =
      mean(
        is.na(avg_culture_wage)
      ),
    
    links_na =
      sum(
        is.na(culture_workers)
      ),
    
    links_na_pct =
      mean(
        is.na(culture_workers)
      )
  )


did_lpg %>%
  group_by(
    did_treated
  ) %>%
  summarise(
    
    wage_missing =
      mean(
        is.na(avg_culture_wage)
      ),
    
    links_missing =
      mean(
        is.na(culture_workers)
      )
  )


did_lpg %>%
  group_by(
    lpg_group
  ) %>%
  summarise(
    
    wage_missing =
      mean(
        is.na(avg_culture_wage)
      ),
    
    links_missing =
      mean(
        is.na(culture_workers)
      )
  )


# -----------------------------
# Save all Estimation Data Frames and Additionals
# -----------------------------

save(
  did_lpg,
  did_treat_map,
  mod_did_links,
  mod_did_wage,
  mod_score,
  panel,
  score_lpg,
  diagnostics,
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0("estimacao_", SCOPE, ".RData")
  )
)
cat(
  sprintf(
    "✅ All data frames have been successfully saved as 'estimacao_%s.RData'.\n",
    SCOPE
  )
)
cat(
  "📦 File location:",
  normalizePath(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("estimacao_", SCOPE, ".RData")
    )
  ),
  "\n"
)

