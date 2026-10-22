# MARCHA — Lei Paulo Gustavo
# Pipeline principal da pesquisa.
# Execute a partir da pasta do projeto (MLPD.Rproj).
# A execução pode consultar serviços externos e levar muitas horas.

options(stringsAsFactors = FALSE)

source("groundhog_init.R")
source("config.R")

output_file <- function(prefix) {
  file.path(DIR.OUTPUT.PROJECT, paste0(prefix, "_", SCOPE, ".RData"))
}

run_step <- function(script) {
  message("Iniciando ", script, " ...")
  step_env <- new.env(parent = globalenv())
  sys.source(script, envir = step_env)
  message("Concluído: ", script)
}

require_output <- function(path, step) {
  if (!file.exists(path)) {
    stop("A etapa ", step, " terminou sem criar o arquivo esperado: ", path,
         call. = FALSE)
  }
}

# 1. Construção das bases integradas
built_output <- output_file("dados")
if (!file.exists(built_output)) {
  run_step("built.R")
} else {
  message("Usando base integrada existente: ", built_output)
}
require_output(built_output, "built.R")

# 2. Painel e grupos de análise
run_step("group_balance.R")
require_output(output_file("painel"), "group_balance.R")

# 3. Estimações principais
run_step("estimation.R")
require_output(output_file("estimacao"), "estimation.R")

# 4. Heterogeneidade educacional e regional
run_step("heterogeneity_estimation.R")
require_output(output_file("estimacao_heterogeneidade"),
               "heterogeneity_estimation.R")

# 5. Análises eleitorais e consolidação de objetos para os gráficos
run_step("electoral_estimation.R")
require_output(output_file("figuras"), "electoral_estimation.R")

# 6. Exportação final de figuras e tabelas
run_step("fig_built.R")
if (!dir.exists(DIR.FIGURES) || !dir.exists(DIR.TABLES)) {
  stop("A etapa fig_built.R não deixou as pastas de figuras e tabelas disponíveis.",
       call. = FALSE)
}

message("Pipeline concluído. Revise os arquivos gerados em: ", DIR.OUTPUT.PROJECT)
