# ================================
# PROJECT: MLPD
# LEAD:    GUSTAVO PINTO
# SCRIPT:  BUILT  
# AUTHOR:  THIAGO CATARINO
# AIM:     Merge Data Panel 
# NOTE: BigQuery queries and external API calls have been preserved in the code
# for methodological transparency. However, reproducing the results of this
# dissertation only requires the .RData files provided with the project.
# Executing the original queries is not necessary.
# ================================
# 1: - Total execution time: 900 min

# ENVIRONMENT SETUP ------------------------------------------------------------

if (!exists("DIR.OUTPUT.PROJECT")) {
  source("config.R")
}

if (!"groundhog" %in% loadedNamespaces()) {
  source("groundhog_init.R")
}

# # # # ADDING AND NAMING THE MAIN DATASETS

# Expenditures on Culture - SICONFI
#
# =========================================================
# Collection and aggregation (RREO Annex 02) - Function 13: Culture
# Series 2015–2023 | ALL Brazilian Municipalities
# Final data frame: siconfi_cultura
# =========================================================


municipios <- get_municipios()


# ---------------------------------
# Execution: ALL years x ALL municipalities
# ---------------------------------

if (!exists("siconfi_cultura")) {
  
  if (file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      "siconfi_cultura.RData"
    )
  )) {
    load(
      file.path(
        DIR.OUTPUT.PROJECT,
        "siconfi_cultura.RData"
      )
    )
  } else {
    resultados <- list()
    for (a in anos) {
      for (i in seq_len(nrow(municipios))) {
        mun_code <- municipios$mun_cod[i]
        cat(sprintf("Processando ano %d | %s - %s (%d)...\n",
                    a, municipios$mun_nome[i], municipios$uf_sigla[i], mun_code))
        
        tmp <- tryCatch(
          process_mun_ano(mun_code, a),
          error = function(e) {
            warning(e$message)
            tibble(ano = a, mun_cod = mun_code, coluna = character(), total = double())
          }
        )
        
        if (nrow(tmp)) resultados[[length(resultados) + 1]] <- tmp
        
        if (!is.na(throttle_sec) && throttle_sec > 0) Sys.sleep(throttle_sec)
      }
    }
# ---------------------------------
# (FINAL) Data frame 
# ---------------------------------
siconfi_cultura <- bind_rows(resultados) %>%
  left_join(municipios, by = "mun_cod") %>%
  relocate(mun_nome, uf_sigla, .after = mun_cod) %>%
  arrange(ano, uf_sigla, mun_nome, coluna) %>%
  rename(year = ano, cod_ibge = mun_cod)

siconfi_cultura <- siconfi_cultura %>% rename(cod_ibge = mun_cod)
  }
}

# =========================================================
# Transfers under the Paulo Gustavo Law
# Federal Cultural Transfers to Municipal Governments
# Reference Year: 2023 | All Brazilian Municipalities
# Final data frame: lpg_cultura
# =========================================================
lpg_cultura <- read_csv("data/PauloGustavo - 6 - Painel de Utilização - Lista Município_Detalhamento Municípios_Tabela.csv")

lpg_cultura <- lpg_cultura %>%
  rename(
    cod_ibge        = IBGE,
    uf_abbrev       = UF,
    muni_name       = `Município`,
    plan_goal       = `Meta do Plano`,
    pay_date        = `Data Pgto`,
    transferred_val = `Valor Transferido`,
    yield_val       = `Rendimento*`,
    balance_val     = `Saldo em conta`,
    used_val_rs     = `Valor Utilizado (R$)`,
    used_val_pct    = `Valor Utilizado (%)**`
  ) %>%
  mutate(cod_ibge = as.integer(cod_ibge))


# ---------------------------------------------------------------
# 🎯 (ANALYSIS SCOPE)
# Select the portion of the Paulo Gustavo Law to be analyzed.
# This parameter propagates through the entire pipeline.
# ---------------------------------------------------------------
# LPG SCOPE FILTER ------------------------------------------------

if (SCOPE == "audiovisual") {
  lpg_cultura <- lpg_cultura %>%
    filter(plan_goal == "Audiovisual")
  
} else if (SCOPE == "outras_artes") {
  lpg_cultura <- lpg_cultura %>%
    filter(plan_goal == "Outras Áreas")
}
# =========================================================
# Cultural Labour Market Indicators (RAIS)
# Aggregated Employment, Wages and Working Hours by CNAE
# Series 2015–2025 | Brazilian Municipalities
# Final data frame: rais_cultura
# =========================================================

data_scope <- file.path(
  DIR.OUTPUT.PROJECT,
  paste0("emprego_", SCOPE, ".RData")
)

if (file.exists(data_scope)) {

  load(data_scope)

  message(
    paste0(
      "✅ emprego_",
      SCOPE,
      ".RData carregado."
    )
  )

} else {

  message(
    paste0(
      "⚠️ emprego_",
      SCOPE,
      ".RData não encontrado. Executando query..."
    )
  )

  billing_project_id <- Sys.getenv("BD_BILLING_PROJECT_ID", unset = "")
  if (!nzchar(billing_project_id)) {
    stop("Defina BD_BILLING_PROJECT_ID no ambiente antes de executar consultas BigQuery.",
         call. = FALSE)
  }
  basedosdados::set_billing_id(billing_project_id)
  cnaes_sql <- paste(
    sprintf("'%s'", cnaes_scope),
    collapse = ","
  )
  
  query_rais <- glue::glue("
-- SKINNY RAIS (2015–2025) • agregado e com dicionários mínimos (fix BOOL+BOOL)
WITH base AS (
  SELECT
    dados.ano,
    dados.sigla_uf,
    dados.id_municipio,
    dados.cnae_2_subclasse,
    dados.sexo,
    dados.raca_cor,
    dados.quantidade_horas_contratadas,
    dados.valor_salario_contratual,

    -- média mensal do vínculo considerando apenas meses não nulos
    SAFE_DIVIDE(
      COALESCE(dados.valor_remuneracao_janeiro,0) +
      COALESCE(dados.valor_remuneracao_fevereiro,0) +
      COALESCE(dados.valor_remuneracao_marco,0) +
      COALESCE(dados.valor_remuneracao_abril,0) +
      COALESCE(dados.valor_remuneracao_maio,0) +
      COALESCE(dados.valor_remuneracao_junho,0) +
      COALESCE(dados.valor_remuneracao_julho,0) +
      COALESCE(dados.valor_remuneracao_agosto,0) +
      COALESCE(dados.valor_remuneracao_setembro,0) +
      COALESCE(dados.valor_remuneracao_outubro,0) +
      COALESCE(dados.valor_remuneracao_novembro,0) +
      COALESCE(dados.valor_remuneracao_dezembro,0),
      CAST(dados.valor_remuneracao_janeiro    IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_fevereiro  IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_marco      IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_abril      IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_maio       IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_junho      IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_julho      IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_agosto     IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_setembro   IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_outubro    IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_novembro   IS NOT NULL AS INT64) +
      CAST(dados.valor_remuneracao_dezembro   IS NOT NULL AS INT64)
    ) AS rem_media_mensal_vinculo
  FROM `basedosdados.br_me_rais.microdados_vinculos` AS dados
  WHERE dados.ano BETWEEN 2015 AND 2025
    AND dados.cnae_2_subclasse IN ({cnaes_sql})
    )
SELECT
  b.ano,
  b.sigla_uf,
  uf.nome AS sigla_uf_nome,
  b.id_municipio,
  m.nome  AS id_municipio_nome,
  b.cnae_2_subclasse,
  c2.descricao_subclasse AS cnae_2_subclasse_descricao,
  b.sexo,
  b.raca_cor,

  COUNT(*)                            AS n_vinculos,
  AVG(b.rem_media_mensal_vinculo)     AS remun_media_mensal,        -- média entre vínculos
  AVG(b.valor_salario_contratual)     AS salario_contratual_medio,
  AVG(b.quantidade_horas_contratadas) AS horas_contratadas_medias

FROM base b
LEFT JOIN (SELECT DISTINCT sigla, nome
           FROM `basedosdados.br_bd_diretorios_brasil.uf`) AS uf
  ON b.sigla_uf = uf.sigla
LEFT JOIN (SELECT DISTINCT id_municipio, nome
           FROM `basedosdados.br_bd_diretorios_brasil.municipio`) AS m
  ON b.id_municipio = m.id_municipio
LEFT JOIN (SELECT DISTINCT subclasse, descricao_subclasse
           FROM `basedosdados.br_bd_diretorios_brasil.cnae_2`) AS c2
  ON b.cnae_2_subclasse = c2.subclasse
GROUP BY
  b.ano, b.sigla_uf, uf.nome, b.id_municipio, m.nome,
  b.cnae_2_subclasse, c2.descricao_subclasse,
  b.sexo, b.raca_cor
ORDER BY b.ano, b.sigla_uf, id_municipio, b.cnae_2_subclasse, b.sexo, b.raca_cor
"
)
  
  rais_cultura <- read_sql(query_rais, billing_project_id = get_billing_id())
  
  rais_cultura <- rais_cultura %>% 
    rename(year = ano, cod_ibge = id_municipio) %>% 
    mutate(cod_ibge = as.integer(cod_ibge))
  
  save(
    rais_cultura,
    file = file.path(
      DIR.OUTPUT.PROJECT,
      paste0("emprego_",
             SCOPE,
             ".RData")
    )
  )
}

# =========================================================
# Municipal Gross Domestic Product (GDP)
# IBGE Municipal Accounts
# Series 2015–2023 | Brazilian Municipalities
# Final data frame: pib_municipal
# =========================================================

if (
  file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      "pib_municipal.RData"
    )
  )
) {
  
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      "pib_municipal.RData"
    )
  )
  
  message(
    "✅ pib_municipal.RData carregado."
  )
  
} else {
  
  message(
    "⚠️ pib_municipal.RData não encontrado. Executando query..."
  )
  
  
  base_url <- "https://apisidra.ibge.gov.br/values/t/5938/n6/all/v/37/p/"
  
  
  anos <- 2015:2023
  
  lista <- list()
  
  for (ano in anos) {
    cat("Baixando ano:", ano, "\n")
    
    url <- paste0(base_url, ano)
    res <- GET(url)
    txt <- content(res, "text", encoding = "UTF-8")
    
    #  protecting against API errors 
    if (grepl("Quantidade de valores", txt)) {
      warning(paste("Erro no ano", ano))
      next
    }
    
    data_raw <- fromJSON(txt)
    
    df <- as.data.frame(data_raw[-1, ])
    colnames(df) <- data_raw[1, ]
    
    lista[[as.character(ano)]] <- df
  }
  
  # joining
  pib_municipal <- bind_rows(lista)
  
  # cleaning
  pib_municipal <- pib_municipal %>%
    rename (cod_ibge = `Município (Código)`,
            name_muni = Município
    ) %>%
    mutate(
    pib = as.numeric(Valor) * 1000,
    year = as.numeric(Ano),
    cod_ibge = as.integer(cod_ibge)
    ) %>%
    select (pib,cod_ibge,year,name_muni)
  
  
  rm(base_url, anos, lista, res, txt, data_raw, df)
  
  save(
    pib_municipal,
    file = file.path(
      DIR.OUTPUT.PROJECT,
      paste0("pib_municipal.RData")
    )
  )
}

# =========================================================
# Municipal GDP per Capita
# Derived from GDP and Population Estimates (IBGE)
# Series 2015–2023 | Brazilian Municipalities
# Final data frame: pib_per_capita
# =========================================================

if (
  file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      "pop_municipal.RData"
    )
  )
) {
  
  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      "pop_municipal.RData"
    )
  )
  
  message(
    "✅ pop_municipal.RData carregado."
  )
  
} else {
  
  message(
    "⚠️ pop_municipal.RData não encontrado. Executando query..."
  )
  
  query_pop <- "
SELECT
  dados.id_municipio AS cod_ibge,
  dados.ano AS ano,
  dados.populacao AS populacao
FROM `basedosdados.br_ibge_populacao.municipio` AS dados
"
  pop_municipal <- basedosdados::read_sql(query_pop) %>%
    arrange(ano) %>%
    filter(ano >= 2015, ano <= 2023) %>%
    mutate(
      cod_ibge   = as.integer(cod_ibge),
      year        = as.integer(as.numeric(ano)),
      pop  = as.numeric(populacao)
    )

  
  
 
  save(
   pop_municipal,
    file = file.path(
      DIR.OUTPUT.PROJECT,
      paste0("pop_municipal.RData")
    )
  )
  
}



pib_municipal <- pib_municipal %>%
  left_join(pop_municipal, by = c("cod_ibge", "year")) %>%
  mutate(pib_pc = pib / pop) %>%
  select(cod_ibge,year,name_muni,pib,pop,pib_pc)



# =========================================================
# Educational Performance Indicators
# Basic Education Development Index (IDEB)
# Historical Series | Brazilian Municipalities
# Final data frame: ideb_educ
# =========================================================

ideb_educ <- read_csv("data/br_inep_ideb_municipio.csv")


ideb_educ <- ideb_educ %>%
  mutate(id_municipio = as.integer(id_municipio)) %>% 
  rename(cod_ibge = id_municipio, educacao = anos_escolares, year = ano)



ideb_educ <- ideb_educ %>% filter(educacao == "finais (6-9)",
  rede == "municipal")  %>% 
  arrange(year)  %>%
  filter(year >= 2015, year <= 2025)  %>%
  mutate(
    year = as.integer(year)
  ) 


ideb_educ <- ideb_educ %>%
  mutate(across(where(bit64::is.integer64), as.integer))


# =========================================================
# Educational Attainment Distribution
# Share of Population Aged 18+ by Level of Education
# Population Census 2022 | Brazilian Municipalities
# Final data frame: superior_educ
# =========================================================

superior_educ <- read_excel("data/highereduc.xlsx")

# =========================================================
# Electoral Results Database
# Candidate-Level Municipal Election Results (TSE)
# Series 2014–2024 | Brazilian Municipalities
# Final data frame: eleitoral_cultura
# =========================================================

if (
  file.exists(
    file.path(
      DIR.OUTPUT.PROJECT,
      "eleitoral_cultura.RData"
    )
  )
) {

  load(
    file.path(
      DIR.OUTPUT.PROJECT,
      "eleitoral_cultura.RData"
    )
  )

  message(
    "✅ eleitoral_cultura.RData carregado."
  )

} else {

  message(
    "⚠️ eleitoral_cultura.RData não encontrado. Executando query..."
  )

  query_elect <- "
SELECT
    dados.ano as ano,
    dados.turno as turno,
    dados.id_eleicao as id_eleicao,
    dados.tipo_eleicao as tipo_eleicao,
    dados.data_eleicao as data_eleicao,
    dados.sigla_uf AS sigla_uf,
    diretorio_sigla_uf.nome AS sigla_uf_nome,
    dados.id_municipio AS id_municipio,
    diretorio_id_municipio.nome AS id_municipio_nome,
    dados.id_municipio_tse AS id_municipio_tse,
    diretorio_id_municipio_tse.nome AS id_municipio_tse_nome,
    dados.cargo as cargo,
    dados.numero_partido as numero_partido,
    dados.sigla_partido as sigla_partido,
    dados.titulo_eleitoral_candidato as titulo_eleitoral_candidato,
    dados.sequencial_candidato as sequencial_candidato,
    dados.numero_candidato as numero_candidato,
    dados.resultado as resultado,
    dados.votos as votos
FROM `basedosdados.br_tse_eleicoes.resultados_candidato` AS dados
LEFT JOIN (SELECT DISTINCT sigla,nome  FROM `basedosdados.br_bd_diretorios_brasil.uf`) AS diretorio_sigla_uf
    ON dados.sigla_uf = diretorio_sigla_uf.sigla
LEFT JOIN (SELECT DISTINCT id_municipio,nome  FROM `basedosdados.br_bd_diretorios_brasil.municipio`) AS diretorio_id_municipio
    ON dados.id_municipio = diretorio_id_municipio.id_municipio
LEFT JOIN (SELECT DISTINCT id_municipio_tse,nome  FROM `basedosdados.br_bd_diretorios_brasil.municipio`) AS diretorio_id_municipio_tse
    ON dados.id_municipio_tse = diretorio_id_municipio_tse.id_municipio_tse
WHERE dados.ano BETWEEN 2014 AND 2024 
"

eleitoral_cultura <- read_sql(query_elect, billing_project_id = get_billing_id())

save(
  eleitoral_cultura,
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0("eleitoral_cultura.RData")
  )
)
}

# -----------------------------
# Save Culture Data Frames and Additionals
# -----------------------------

save(
  siconfi_cultura,
  lpg_cultura,
  rais_cultura,
  pib_municipal,
  ideb_educ,
  superior_educ,
  eleitoral_cultura,
  file = file.path(
    DIR.OUTPUT.PROJECT,
    paste0("dados_", SCOPE, ".RData")
  )
)

cat(
  sprintf(
    "✅ All data frames have been successfully saved as 'dados_%s.RData'.\n",
    SCOPE
  )
)
getwd()
cat(
  "📦 File location:",
  normalizePath(
    file.path(
      DIR.OUTPUT.PROJECT,
      paste0("dados_", SCOPE, ".RData")
    )
  ),
  "\n"
)

