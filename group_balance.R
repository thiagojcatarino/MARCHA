# ================================
# PROJECT: MLPD
# LEAD:    GUSTAVO PINTO
# SCRIPT:  GROUP BALANCE 
# AUTHOR:  THIAGO CATARINO
# AIM:     Create treatment and control groups and generate checks/balancing
# NOTES:   Run after ‘built’ has generated 'dados_cultura.RData'
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
# CULTURE DATABASES
# ---------------------------------------------------------------
# If the main data frames are already loaded in memory,
# no action is required.
# Otherwise, load them from 'dados_cultura.RData'.
# ===============================================================

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

# ===============================================================
# 🧮 Standardization of IBGE codes across all databases
# ---------------------------------------------------------------
#  1) Creates the standardized columns `cod_ibge` and `id_muni` (7 digits).
# ===============================================================

rais_cultura <- rais_cultura %>%
  mutate(
    id_muni  = fix_ibge(cod_ibge),
    year     = as.integer(year),
  )

siconfi_cultura <- siconfi_cultura %>%
  mutate(
    year     = as.integer(year),
    id_muni  = fix_ibge(cod_ibge)
  )

lpg_cultura <- lpg_cultura %>%
  mutate(
    cod_ibge = fix_ibge(cod_ibge),
    year     = as.integer(
      lubridate::year(lubridate::dmy(as.character(pay_date), quiet = TRUE))
  ))

pib_municipal <- pib_municipal %>%
  mutate(
    cod_ibge = as.integer(fix_ibge(cod_ibge)),
    year     = as.integer(year),
    pib      = as.numeric(pib),
    pop = as.numeric(pop),
    pib_pc   = as.numeric(pib_pc)
  )


# 2)  count the lengths (without converting them to numbers)
lpg_cultura %>%
  mutate(len = nchar(cod_ibge)) %>%
  count(len)

# 3) check out some “bad” lines
bad_rows <- lpg_cultura %>%
  mutate(len = nchar(cod_ibge)) %>%
  filter(is.na(cod_ibge) | len != 7)

bad_rows %>% select(cod_ibge, len, muni_name, uf_abbrev, pay_date) %>% head(20)

# 4) how many of them match the official dictionary?
ibge_ref <- readRDS(
  file.path(
    DIR.OUTPUT.PROJECT,
    "geobr",
    "municipios_dict_2019.rds"
  )
)

match_n <- lpg_cultura %>%
  mutate(cod_ibge_num = as.numeric(cod_ibge)) %>%
  semi_join(ibge_ref, by = c("cod_ibge_num" = "code_muni")) %>%
  nrow()

match_n

# This snippet corrects and validates the municipality codes (cod_ibge) 
# in the LPG database.
# It creates an official IBGE dictionary with standardized names, 
# removes accents, and standardizes state codes (UF),
# cross-references municipalities by name and state 
# to replace incorrect codes with the official ones
# separates valid rows (good_rows) from invalid ones (bad_rows),
# showing how many still do not match the IBGE (mismatch_n), 
# and, finally, addresses residual inaccuracies in the IBGE codes


# 1) IBGE Dictionary (with standardized names) and checking for ambiguous keys
ibge_dic <- readRDS(
  file.path(
    DIR.OUTPUT.PROJECT,
    "geobr",
    "ibge_dic_2019.rds"
  )
)

ambiguous_keys <- ibge_dic %>%
  count(abbrev_state, name_norm) %>%
  filter(n > 1)          # names that appear more than once in the same state

ibge_dic_unique <- ibge_dic %>%
  anti_join(ambiguous_keys, by = c("abbrev_state","name_norm")) %>%
  transmute(
    uf_abbrev  = abbrev_state,
    name_norm,
    code_muni,
    cod_ibge_ref = stringr::str_pad(as.character(code_muni), 7, "left", "0")
  )

# 2) Normalize the name and state in your database 
#    and join by (state, normalized_name) ONLY on unique keys
lpg_norm <- lpg_cultura %>%
  mutate(
    uf_abbrev  = toupper(uf_abbrev),
    name_norm  = norm_name(muni_name)
  )

lpg_joined <- lpg_norm %>%
  left_join(ibge_dic_unique, by = c("uf_abbrev","name_norm"))

# 3) Update cod_ibge only when:
#    (a) the current value is not valid in the dictionary, and
#    (b) the match by name+state was unique (code_muni is not NA)
ibge_valid <- ibge_dic_unique %>% distinct(cod_ibge_ref)

lpg_cultura <- lpg_joined %>%
  mutate(
    cod_ibge = if_else(
      cod_ibge %in% ibge_valid$cod_ibge_ref,              # is it valid yet?
      cod_ibge,                                           # then keep it
      if_else(!is.na(code_muni), cod_ibge_ref, cod_ibge)  # otherwise, replace it
    )                                                     # with the official one
  ) %>%                                                    
  select(-code_muni, -cod_ibge_ref)  # limpeza de colunas auxiliares

# 4) Final validation (how many still don't match the IBGE data?)
mismatch_n <- lpg_cultura %>%
  anti_join(
    ibge_dic_unique %>% select(cod_ibge_ref) %>% rename(cod_ibge = cod_ibge_ref),
    by = "cod_ibge"
  ) %>%
  nrow()

mismatch_n



bad_rows <- lpg_cultura%>%
  mutate(cod_ibge = as.numeric(cod_ibge)) %>%
  anti_join(ibge_ref, by = c("cod_ibge" = "code_muni"))

bad_rows %>% distinct(cod_ibge)
bad_rows %>% glimpse()

good_rows <- lpg_cultura %>%
  mutate(cod_ibge = as.numeric(cod_ibge)) %>%
  semi_join(ibge_ref, by = c("cod_ibge" = "code_muni"))


# Inconsistencies in the IBGE codes were identified in 26 municipalities 
# in the LPG database and were manually corrected based on a name-by-name 
# comparison with the official IBGE registry.

fix_ibge_code <- tibble::tibble(
  cod_ibge_old = c(
    "0150295","0150650","0170600","0170825","0172049",
    "0230630","0240130","0241030","0260160","0260690",
    "0260850","0280010","0292225","0292850","0310890",
    "0312290","0316520","0330380","0330590","0351500",
    "0351610","0353080","0355000","0431710","0510700"
  ),
  cod_ibge_new = c(
    "1502954","1506500","1706001","1708254","1720499",
    "2306306","2401305","2410306","2601607","2606903",
    "2608503","2800100","2922250","2928505","3108909",
    "3122900","3165206","3303807","3305901","3515004",
    "3516101","3530805","3550001","4317103","5107008"
  )
)



lpg_cultura <- lpg_cultura %>%
  left_join(fix_ibge_code, by = c("cod_ibge" = "cod_ibge_old")) %>%
  mutate(
    cod_ibge = coalesce(cod_ibge_new, cod_ibge)
  ) 



# One municipality with no code was marked as UNKNOWN

lpg_cultura <- lpg_cultura %>%
  mutate(
    cod_ibge = if_else(is.na(cod_ibge), "UNKNOWN", cod_ibge)
  )



# ================================
#  🧮 LPG Improvements
# ================================


lpg_cultura <- lpg_cultura %>%
  mutate(
    transferred_val = brl_to_num(transferred_val),
    yield_val       = brl_to_num(yield_val),
    balance_val     = brl_to_num(balance_val),
    used_val_rs     = brl_to_num(used_val_rs),
    used_val_pct    = brl_to_num(gsub("%","", used_val_pct))
  )


# --- [A] LPG: robust year extraction (place right after your LPG rename/mutate) ---

lpg_cultura <- lpg_cultura %>%
  mutate(
    pay_date_chr = as.character(pay_date),
    year_fix = coalesce(
      year(ymd(pay_date_chr, quiet = TRUE)),
      year(dmy(pay_date_chr, quiet = TRUE)),
      year(mdy(pay_date_chr, quiet = TRUE)),
      suppressWarnings(as.integer(str_extract(pay_date_chr, "(19|20)\\d{2}")))
    ),
    # fallback (ajuste se necessário)
    year_fix = if_else(is.na(year_fix), 2023L, year_fix)
  )


# 
# ✅
# Clean panel, an execution rate, and groups for treatment intensity.
# 



# ================================
#  🧮 Aggregation
# ================================
# --- Aggregate RAIS (municipality-year level) ---
# We sum the employment contracts and calculate the average salary 
# weighted by the number of contracts

rais_muni_year <- rais_cultura %>%
  group_by(cod_ibge, year) %>%
  summarise(
    culture_workers   = sum(n_vinculos, na.rm = TRUE),
    avg_culture_wage  = safe_wmean(remun_media_mensal, n_vinculos),
    .groups = "drop"
  )

# --- 2) Aggregate SICONFI ---

siconfi_muni_year <- siconfi_cultura %>%
  filter(str_detect(coluna, "DESPESAS LIQUIDADAS ATÉ O BIMESTRE")) %>%
  group_by(cod_ibge, year) %>%
  summarise(
    culture_exp_total = sum(total, na.rm = TRUE),
    .groups = "drop"
  )

# --- 3) Aggregate LPG ---
# --- [B] LPG: aggregate to municipality-year using year_fix ---
lpg_muni_year <- lpg_cultura %>%
  mutate(
    cod_ibge = as.integer(cod_ibge),
    year     = as.integer(year)
  ) %>%
  group_by(cod_ibge, year) %>%
  summarise(
    lpg_transferred = sum(transferred_val, na.rm = TRUE),
    lpg_used        = sum(used_val_rs,    na.rm = TRUE),
    .groups = "drop"
  )

# --- 4) Is IDEB Aggregated? ---

ideb_educ %>%
  count(cod_ibge, year) %>%
  filter(n > 1)

# --- 5) Treatment variable: execution rate and groups ---
# --- [C] PANEL: clean old LPG fields, rejoin, and recompute treatment ---
# remove stale versions if they exist (safe no-op if they don't)

# The ‘backbone’ object contains only the identification keys 
# (cod_ibge and year),
# forming the framework with all existing municipality-year combinations
# in the databases.
# The ‘panel’, on the other hand, is the final analytical table: 
# it joins the aggregated variables from each source 
# (RAIS, SICONFI, and LPG) to the backbone using left_join(), 
# consolidating into a single table all the information necessary for analysis.



# ============================================================
# 🌐 BACKBONE: create a single municipality-year database
# ============================================================


backbone <- bind_rows(
  rais_muni_year %>% select(cod_ibge, year),
  siconfi_muni_year %>% select(cod_ibge, year),
  lpg_muni_year %>% select(cod_ibge, year)
) %>%
  distinct(cod_ibge, year, .keep_all = TRUE) %>%
  arrange(cod_ibge, year)


# ============================================================
# 🚨 Detection of duplicate municipality-year entries
# ============================================================
dups <- backbone %>%
  count(cod_ibge, year) %>%
  filter(n > 1)

if (nrow(dups) > 0) {
  warning(sprintf("⚠️ %d combinações duplicadas de município-ano detectadas (ex: %s...).",
                  nrow(dups), paste(unique(dups$id_muni[1:5]), collapse = ", ")))
} else {
  message("✅ Nenhuma duplicação de município-ano detectada.")
}

siconfi_muni_year <- siconfi_muni_year %>%
  mutate(across(where(bit64::is.integer64), as.integer))

lpg_muni_year <- lpg_muni_year %>%
  mutate(across(where(bit64::is.integer64), as.integer))

ideb_educ <- ideb_educ %>%
  mutate(across(where(bit64::is.integer64), as.integer))


# ============================================================
# 🌐 PANEL: create the final analytical table
# ============================================================



panel <- backbone %>%
  left_join(rais_muni_year,    by = c("cod_ibge","year")) %>%
  left_join(siconfi_muni_year, by = c("cod_ibge","year")) %>%
  left_join(lpg_muni_year,     by = c("cod_ibge","year")) %>%
  left_join(pib_municipal,     by = c("cod_ibge","year")) %>%
  left_join(ideb_educ,         by = c("cod_ibge","year"))
 


# Create the policy treatment variable (Paulo Gustavo Law).
# 1) Remove old versions of the columns, if any, to avoid conflicts.
# 2) Calculate the execution rate (lpg_exec_rate = used / transferred),
#     representing how much of the received funds was actually spent.
# 3) Classify municipalities into usage intensity groups:
#     NO_USE | LOW_USE | MEDIUM_USE | HIGH_USE,
#     which will be used for comparisons and balancing tests.

panel <- panel %>%
  select(-any_of(c("lpg_base","lpg_exec_rate","lpg_group")))

panel <- panel %>%
  mutate(
    lpg_base      = if_else(!is.na(lpg_transferred) & lpg_transferred > 0, lpg_transferred, NA_real_),
    lpg_exec_rate = if_else(!is.na(lpg_base) & lpg_base > 0, lpg_used / lpg_base, NA_real_)
  )

breaks <- c(-Inf, 0, 0.25, 0.75, Inf)
labels <- c("NO_USE", "LOW_USE", "MEDIUM_USE", "HIGH_USE")

panel <- panel %>%
  mutate(
    lpg_group = cut(lpg_exec_rate, breaks = breaks, labels = labels, right = TRUE, ordered_result = TRUE)
  )




# ================================
# ✅ Balance Check:
# how similar are municipalities that used nothing vs. those that used a lot.
# ================================
# Define the baseline (pre-policy) variables to be compared.
# Calculate, for each municipality (2015–2019), the average of these variables—
# representing typical behavior prior to the LPG—and attaches these
# averages to the main panel. 
# Define the post-policy years (2023/2024)
# and the names of the baseline variables to be used in the comparison.

# Baseline variables (before policy)
baseline_vars <- c("avg_culture_wage", "culture_exp_total", "pib", "ideb")


baseline <- panel %>%
  filter(year %in% 2015L:2019L)%>% ## 2020 and 2021 are the PANDEMICS PERIOD
  group_by(cod_ibge) %>%
  summarise(across(all_of(baseline_vars), ~mean(.x, na.rm = TRUE), .names = "{.col}_bl"), .groups = "drop")

panel <- panel %>% left_join(baseline, by = "cod_ibge")

# --- [D] BALANCE: pick a valid post-policy year and compute diff safely ---
bal_year <- 2023L:2024L
bal_vars <- paste0(baseline_vars, "_bl")



# Tabela de balanceamento robusta a grupos ausentes
# Os municípios que usaram os recursos da LPG (HIGH_USE) 
# já eram parecidos,  antes de 2023, 
# com os que não usaram (NO_USE)?”

# Cria uma tabela de balanceamento (balance_table)
# que compara, no ano pós-política (bal_year = 2024),
# as médias das variáveis de baseline (2015–2019) entre
# municípios que não usaram os recursos da LPG (NO_USE)
# e os que usaram de forma intensa (HIGH_USE).
# Inclui a diferença (diff = HIGH_USE - NO_USE) e trata
# automaticamente casos em que algum grupo não exista.

balance_table <- panel %>%
  dplyr::filter(year %in% 2023L:2024L) %>%
  dplyr::select(cod_ibge, lpg_group, dplyr::all_of(bal_vars)) %>%
  tidyr::pivot_longer(dplyr::all_of(bal_vars), names_to = "variable", values_to = "value") %>%
  dplyr::summarise(
    HIGH_USE   = mean(value[lpg_group == "HIGH_USE"], na.rm = TRUE),
    LOW_NO_USE = mean(value[lpg_group %in% c("NO_USE", "LOW_USE")], na.rm = TRUE),
    .by = "variable"
  ) %>%
  dplyr::mutate(
    HIGH_USE   = as.numeric(HIGH_USE),
    LOW_NO_USE = as.numeric(LOW_NO_USE),
    diff       = dplyr::coalesce(HIGH_USE, 0) - dplyr::coalesce(LOW_NO_USE, 0)
  )

print(balance_table)
glimpse(panel)

# Diagnóstico de grupos e implicações: Em 2023, há 132 municípios em LOW_USE e 343 em NO_USE
# (além de 4.685 em HIGH_USE), mas os testes mostram que LOW_USE e NO_USE não aparecem na RAIS (até 2019)
# nem no SICONFI – Função 13 (até 2019): nrow(low_in_rais) = 0; nrow(no_in_rais) = 0; nrow(low_in_siconfi) = 0;
# nrow(no_in_siconfi) = 0. Por isso, suas médias de baseline (2015–2019)
# ficam totalmente ausentes (nonmiss_* = 0) e as médias pós-filtragem viram NaN para esses grupos;
# já HIGH_USE exibiu presença e atividade prévia (ex.: mean_workers ≈ 18; mean_wage ≈ 1083),
# o que confirma a consistência do baseline para esse estrato. Em termos substantivos,
# o achado indica que a LPG alcançou municípios sem histórico cultural formal
# (emprego RAIS e gasto orçamentário em cultura), o que é crucial para a análise:
#   (i) explica por que a balance_table não pode comparar NO_USE vs HIGH_USE em 2023–2024,
# (ii) sugere que o contraste informativo é LOW_USE vs HIGH_USE ou o uso de 2019 como pré-política,
# e (iii) orienta extensões úteis (variável had_cultural_history, mapas de cobertura
# e controles de capacidade administrativa) para robustecer identificação e interpretação
# dos efeitos da política.


# ===============================================================
# 🧮 BALANCE TABLE — HIGH_USE vs LOW_NO_USE (2023–2024)
# ---------------------------------------------------------------
# Objetivo:
#   • Combinar LOW_USE e NO_USE em um único grupo ("LOW_NO_USE");
#   • Comparar com HIGH_USE na média das variáveis de baseline;
#   • Avaliar a proporção de municípios com baseline preenchido.
# ===============================================================

# 1) Agrupar LOW_USE e NO_USE como um grupo só (Municipios MEDIUM_USE = NA)
# panel <- panel %>%
#   mutate(
#     lpg_group_merged = case_when(
#       lpg_group %in% c("LOW_USE", "NO_USE") ~ "LOW_NO_USE",
#       lpg_group == "HIGH_USE" ~ "HIGH_USE",
#       TRUE ~ NA_character_
#     )
#   )

panel <- panel %>%
  mutate(
    lpg_group_merged = case_when(
      lpg_group %in% c("LOW_USE", "NO_USE") ~ "LOW_NO_USE",
      lpg_group == "HIGH_USE" ~ "HIGH_USE",
      lpg_group == "MEDIUM_USE" ~ NA_character_
    )
  )



# 2) Construir a tabela de balanceamento
balance_table <- panel %>%
  filter(year %in% 2023L:2024L, lpg_group_merged %in% c("LOW_NO_USE", "HIGH_USE")) %>%
  select(cod_ibge, lpg_group_merged, all_of(bal_vars)) %>%
  pivot_longer(all_of(bal_vars), names_to = "variable", values_to = "value") %>%
  summarise(
    HIGH_USE    = mean(value[lpg_group_merged == "HIGH_USE"],    na.rm = TRUE),
    LOW_NO_USE  = mean(value[lpg_group_merged == "LOW_NO_USE"],  na.rm = TRUE),
    n_valid     = sum(!is.na(value)),                            # total de observações válidas
    n_total     = n(),
    .by = "variable"
  ) %>%
  mutate(
    diff = HIGH_USE - LOW_NO_USE,
    pct_valid = round(100 * n_valid / n_total, 1)
  )

# 3) Relatório de cobertura: quantos municípios têm baseline válido?
coverage_report <- panel %>%
  filter(year %in% 2023L:2024L) %>%
  summarise(
    total = n(),
    valid_baseline = sum(!is.na(avg_culture_wage_bl) | !is.na(culture_exp_total_bl)),
    pct_valid = round(100 * valid_baseline / total, 1)
  )

# 4) Visualização rápida dos resultados
balance_table
coverage_report



# ===============================================================
# 📦 OUTPUT & COVERAGE SUMMARY
# ---------------------------------------------------------------
# This final block saves all key outputs and prints a quick 
# diagnostic summary. It (1) creates an 'out/' directory if 
# missing, (2) exports the main LPG panel and balance table 
# for future use, and (3) prints a yearly summary showing how 
# many municipalities have valid execution rates (lpg_exec_rate). 
# This helps verify that the pipeline ran completely and that 
# coverage across years is consistent.
# ===============================================================
write_csv(
  panel %>% select(cod_ibge, year, lpg_exec_rate, lpg_group),
  file.path(
    DIR.OUTPUT.PROJECT,
    paste0("lpg_groups_", SCOPE, ".csv")
  )
)

saveRDS(
  panel,
  file.path(
    DIR.OUTPUT.PROJECT,
    paste0("panel_with_lpg_", SCOPE, ".rds")
  )
)

saveRDS(
  balance_table,
  file.path(
    DIR.OUTPUT.PROJECT,
    paste0("balance_no_vs_high_", SCOPE, ".rds")
  )
)

cat("\nSummary of lpg_exec_rate by year:\n")

panel %>%
  group_by(year) %>%
  summarise(
    n_obs = n(),
    n_rate = sum(!is.na(lpg_exec_rate)),
    pct = round(100 * n_rate / n_obs, 1)
  ) %>%
  print(n = Inf)

# ============================================================
# 🌿 SUMMARY — LPG PANEL BUILD (Thiago Catarino, 2026)
# ============================================================
# 1. Standardized datasets (RAIS, SICONFI, LPG) with common keys:
#    id_muni (municipality code) and year.
# 2. Built a municipality–year panel joining cultural employment,
#    municipal cultural expenditures, and LPG execution data.
# 3. Created the treatment variable:
#       lpg_exec_rate = lpg_used / lpg_transferred
#    and grouped municipalities into:
#       NO_USE | LOW_USE | MEDIUM_USE | HIGH_USE
# 4. Computed pre-policy baseline (2019–2021 averages) for
#    avg_culture_wage and culture_exp_total, joined to panel.
# 5. Built a balance table comparing NO_USE vs HIGH_USE groups
#    and safely computed diff = HIGH_USE - NO_USE.
# 6. Clean, idempotent code — can be re-run without duplication.
#    Outputs ready for descriptive or econometric analysis.
# ============================================================

# ===============================================================
# 🧭 LPG TREATMENT FLAG & GROUP CHECKS
# ---------------------------------------------------------------
# This section uses the existing lpg_group variable (already 
# defined in the main panel) to create a simple binary treatment 
# indicator (treated = 1 if the municipality used any LPG funds).
# It also summarizes the distribution of treatment groups in 2023,
# helping verify coverage and prepare the data for DiD analysis.
# ===============================================================

# Quick inspection: confirm available years and groups
unique(panel$year)
panel %>% count(year, lpg_group)
summary(panel$lpg_exec_rate)

# Create a binary “treated” variable: 1 = used LPG funds, 0 = did not use
panel <- panel %>%
  mutate(treated = if_else(lpg_group %in% c("LOW_USE", "MEDIUM_USE", "HIGH_USE"), 1, 0, missing = 0))

# Verify proportions of treatment groups in 2023
panel %>%
  filter(year == 2023) %>%
  count(lpg_group) %>%
  mutate(pct = round(100 * n / sum(n), 1))

# Check total unique municipalities in 2023
panel %>%
  filter(year == 2023) %>%
  summarise(unique_muni = n_distinct(cod_ibge))

# DIAGNOSTIC OBJECTS ------------------------------------------------------

diagnostics <- list(
  balance_table   = balance_table,
  coverage_report = coverage_report,
  dups            = dups
)

# ===============================================================
# 🧩 DATA COVERAGE INSIGHT — PRE vs POST LPG
# ---------------------------------------------------------------
# Before the LPG policy (2015–2019), the panel shows strong data 
# coverage in RAIS (employment and wages) but many missing values 
# in the LPG variables — which did not yet exist. After the LPG 
# implementation (2023–2024), this pattern reverses: the RAIS 
# coverage declines (many municipalities with NA values), while 
# LPG-related variables become dense and informative. 
# This shift reflects the natural structure of the panel, where 
# pre-policy years capture labor dynamics and post-policy years 
# capture fund execution and implementation behavior.
# ===============================================================

save(
  panel,
  diagnostics,
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0("painel_", SCOPE, ".RData")
  )
)


# CLEAN ENVIRONMENT -------------------------------------------------------

rm(
  list = setdiff(
    ls(),
    c("panel", "diagnostics")
  )
)

gc()

