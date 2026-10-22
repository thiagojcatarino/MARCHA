# # ================================
# # PROJECT: MLPD
# # LEAD:    GUSTAVO PINTO
# # SCRIPT:  HETEROGENEITY ESTIMATION 
# # AUTHOR:  THIAGO CATARINO
# # AIM:     Estimating Educational and Regional Variations to causal effect of LPG
# # NOTES:   Run after ‘estimation’ has generated 'estimacao_", SCOPE, ".RData'
# # ================================
# # 1: - Total execution time: 1 min
# 

# ENVIRONMENT SETUP ------------------------------------------------------------

if (!exists("DIR.OUTPUT.PROJECT")) {
  source("config.R")
}

if (!"groundhog" %in% loadedNamespaces()) {
  source("groundhog_init.R")
}

# CULTURE DATA -----------------------------------------------------------

if (exists("mod_score")) {
  cat("✅ Estimation objects already available in the environment. Skipping load.\n")
} else if (
  file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("estimacao_", SCOPE, ".RData")
    )
  )
) {
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("estimacao_", SCOPE, ".RData")
    )
  )
  cat(
    sprintf(
      "✅ Estimation objects loaded successfully from 'estimacao_%s.RData'.\n",
      SCOPE
    )
  )
} else {
  stop(
    sprintf(
      "⚠️ File 'estimacao_%s.RData' not found. Please run estimation.R first.",
      SCOPE
    )
  )
}

# HIGHER EDUCATION DATA --------------------------------------------

if (!exists("superior_educ")) {
  
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("dados_", SCOPE, ".RData")
    )
  )
  
  cat(
    sprintf(
      "✅ Higher education data loaded from 'dados_%s.RData'.\n",
      SCOPE
    )
  )
  
}

# INEP (HIGHER DEGREE) ESTIMATION

# mixing lines 2 and 3 to the column names
novos_nomes <- paste(
  names(superior_educ),
  as.character(superior_educ[1, ]),
  as.character(superior_educ[2, ]),
  sep = "_"
)

# cleaning names
novos_nomes <- novos_nomes %>%
  str_replace_all("NA", "") %>%
  str_replace_all("_+", "_") %>%
  str_replace_all("^_|_$", "") %>%
  make_clean_names()

# applying names
names(superior_educ) <- novos_nomes

# removing head lines 
superior_educ <- superior_educ[-c(1,2), ]


# --------------------------------------------------
# 2. Clean SIDRA dataset 
# --------------------------------------------------


superior_educ_bra <- superior_educ[1:1, ]
superior_educ_region <- superior_educ[2:6, ]
superior_educ_state <- superior_educ[7:33, ]

# all the dataset
superior_educ <- superior_educ[-c(1:33), ]


superior_educ <- superior_educ %>%
  
  select(
    municipio_uf = tabela_2_distribuicao_percentual_das_pessoas_de_18_anos_ou_mais_de_idade_por_nivel_de_instrucao_segundo_o_sexo_2022_brasil_grande_regiao_unidade_da_federacao_e_municipio,
    perc_superior_educ               = x5_superior_completo,
    perc_medio_educ           = x4_medio_completo_e_superior_incompleto,
    perc_fundamental_educ             = x3_fundamental_completo_e_medio_incompleto,
    perc_sem_instrucao    = x2_total_sem_instrucao_e_fundamental_incompleto,
  ) %>%
  
  mutate(
    
    uf =
      str_extract(
        municipio_uf,
        "(?<=\\().+(?=\\))"
      ),
    
    municipio =
      str_trim(
        str_remove(
          municipio_uf,
          "\\s*\\(.*\\)"
        )
      )
  )

# --------------------------------------------------
# 3. IBGE Official Table 
# --------------------------------------------------
municipios <- readRDS(
  file.path(
    DIR.OUTPUT.PROJECT,
    "geobr",
    "municipios_2020.rds"
  )
)

# --------------------------------------------------
# 4. Merge - obtaining IBGE code 
# --------------------------------------------------

superior_educ <- superior_educ %>%
  
  left_join(
    municipios,
    
    by = c(
      "municipio",
      "uf"
    )
  )

# --------------------------------------------------
# 5. Keeping only the necessary
# --------------------------------------------------

superior_educ <- superior_educ %>%
  
  select(
    cod_ibge,
    perc_superior_educ,
    perc_medio_educ,
    perc_fundamental_educ,
    perc_sem_instrucao
    
  ) %>%
  
  mutate(
    
    perc_superior_educ =
      as.numeric(perc_superior_educ),
    perc_medio_educ =
      as.numeric(perc_medio_educ),
    perc_fundamental_educ =
      as.numeric(perc_fundamental_educ),
    perc_sem_instrucao =
      as.numeric(perc_sem_instrucao)
  ) %>% 
  
  distinct()

# --------------------------------------------------
# 6. Merge - main dataset 
# --------------------------------------------------

score_lpg <- score_lpg %>%
  
  left_join(
    superior_educ,
    by = "cod_ibge"
  )

# --------------------------------------------------
# 7. Educational Regression 
# --------------------------------------------------

mod_superior_educ <- feols(
  
  score ~
    perc_superior_educ +
    pib_pc +
    culture_exp_pc +
    salario_cultura +
    n_vinculos_cultura +
    pop,
  
  data = score_lpg
)

# --------------------------------------------------
# 8. Regional Regression
# --------------------------------------------------


# the first two digits of cod_ibge inform the brazilian respective state
munis <- tibble(
  cod_ibge = unique(score_lpg$cod_ibge)
) %>%
  mutate(
    uf = substr(as.character(cod_ibge), 1, 2)
  ) %>%
  mutate(
    regiao = case_when(
      uf %in% c("11","12","13","14","15","16","17") ~ "Norte",
      uf %in% c("21","22","23","24","25","26","27","28","29") ~ "Nordeste",
      uf %in% c("31","32","33","35") ~ "Sudeste",
      uf %in% c("41","42","43") ~ "Sul",
      uf %in% c("50","51","52","53") ~ "Centro-Oeste"
    )
  )



score_lpg <- score_lpg %>%
  left_join(
    munis,
    by = "cod_ibge"
  )


mods_regionais <- list(
  
  Norte = feols(
    score ~ perc_superior_educ + pib_pc + culture_exp_pc +
      salario_cultura + n_vinculos_cultura + pop,
    
    data = score_lpg %>%
      filter(regiao == "Norte")
  ),
  
  Nordeste = feols(
    score ~ perc_superior_educ + pib_pc + culture_exp_pc +
      salario_cultura + n_vinculos_cultura + pop,
    
    data = score_lpg %>%
      filter(regiao == "Nordeste")
  ),
  
  Sudeste = feols(
    score ~ perc_superior_educ + pib_pc + culture_exp_pc +
      salario_cultura + n_vinculos_cultura + pop,
    
    data = score_lpg %>%
      filter(regiao == "Sudeste")
  ),
  
  Sul = feols(
    score ~ perc_superior_educ + pib_pc + culture_exp_pc +
      salario_cultura + n_vinculos_cultura + pop,
    
    data = score_lpg %>%
      filter(regiao == "Sul")
  ),
  
  `Centro-Oeste` = feols(
    score ~ perc_superior_educ + pib_pc + culture_exp_pc +
      salario_cultura + n_vinculos_cultura + pop,
    
    data = score_lpg %>%
      filter(regiao == "Centro-Oeste")
  )
)

mean(panel$pib_pc, na.rm = TRUE)


names(score_lpg)[grepl("educ", names(score_lpg))]

# --------------------------------------------------
# 9. Create state variable
# --------------------------------------------------

score_lpg <- score_lpg %>%
  
  mutate(
    
    uf =
      substr(
        as.character(cod_ibge),
        1,
        2
      ),
    
    estado =
      case_when(
        
        uf == "35" ~ "Sao Paulo",
        uf == "31" ~ "Minas Gerais",
        uf == "29" ~ "Bahia",
        uf == "33" ~ "Rio de Janeiro",
        uf == "41" ~ "Parana"
      )
  )

# --------------------------------------------------
# 10. State-level Regressions 
# --------------------------------------------------

mods_estaduais <- list(
  
  `Sao Paulo` = feols(
    
    score ~
      perc_superior_educ +
      pib_pc +
      culture_exp_pc +
      salario_cultura +
      n_vinculos_cultura +
      pop,
    
    data =
      score_lpg %>%
      filter(estado == "Sao Paulo")
  ),
  
  
  `Minas Gerais` = feols(
    
    score ~
      perc_superior_educ +
      pib_pc +
      culture_exp_pc +
      salario_cultura +
      n_vinculos_cultura +
      pop,
    
    data =
      score_lpg %>%
      filter(estado == "Minas Gerais")
  ),
  
  
  Bahia = feols(
    
    score ~
      perc_superior_educ +
      pib_pc +
      culture_exp_pc +
      salario_cultura +
      n_vinculos_cultura +
      pop,
    
    data =
      score_lpg %>%
      filter(estado == "Bahia")
  ),
  
  
  `Rio de Janeiro` = feols(
    
    score ~
      perc_superior_educ +
      pib_pc +
      culture_exp_pc +
      salario_cultura +
      n_vinculos_cultura +
      pop,
    
    data =
      score_lpg %>%
      filter(estado == "Rio de Janeiro")
  ),
  
  
  Parana = feols(
    
    score ~
      perc_superior_educ +
      pib_pc +
      culture_exp_pc +
      salario_cultura +
      n_vinculos_cultura +
      pop,
    
    data =
      score_lpg %>%
      filter(estado == "Parana")
  )
)

# --------------------------------------------------
# 4. Saving
# --------------------------------------------------

save(
  did_lpg,
  did_treat_map,
  panel,
  score_lpg,
  mod_did_links,
  mod_did_wage,
  mod_score,
  mod_superior_educ,
  mods_regionais,
  mods_estaduais,
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0("estimacao_heterogeneidade_", SCOPE, ".RData")
  )
)


