
library(groundhog)

pkgs <- c(
  "tidyverse", "httr", "jsonlite",
  "geobr", "glue", "patchwork", 
  "basedosdados", "dreamerr", "fixest", 
  "stringi", "gt","readxl","janitor","sidrar"
)
groundhog.library(pkgs, "2025-04-21")

suppressPackageStartupMessages(
  library(basedosdados)
)

message("✅ Packages loaded successfully.")
