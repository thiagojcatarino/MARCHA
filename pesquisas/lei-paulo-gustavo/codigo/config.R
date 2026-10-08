
# > THIS SCRIPT
# AIM: SETS ROOT DIRECTORIES & SOURCES BASIC (UBIQUITOUS) FUNCTIONS
#
# > NOTES
# 1: MUST BE SOURCED AT THE VERY BEGINNING OF EVERY R SCRIPT THAT HANDLES CDR

# ---------------------------------------------------------------
# 🎯 ANALYSIS SCOPE
# Select the portion of the Paulo Gustavo Law to be analyzed.
# ---------------------------------------------------------------

 SCOPE <- "cultura"
# SCOPE <- "audiovisual"
# SCOPE <- "outras_artes"

 scope_suffix <- switch(
   SCOPE,
   audiovisual = " - Audiovisual",
   outras_artes = " - Outras Artes",
   ""
 )
# ==========================================================
# # DIRECTORIES --------------------------------
# ==========================================================

# ---------------------------------
# CENTRAL DATA REPOSITORY
# ---------------------------------

DIR.CODE.PROJECT <- getwd()               # root directory for code (version control dirs)

DIR.DATA.PROJECT <- Sys.getenv(
  "MARCHA_DATA_DIR",
  unset = file.path(DIR.CODE.PROJECT, "data")
)

DIR.OUTPUT.PROJECT <- file.path(          # root directory for project outputs
  DIR.CODE.PROJECT,
  "output"
)

dir.create(
  DIR.OUTPUT.PROJECT,
  showWarnings = FALSE,
  recursive = TRUE
)



dir.create(
  file.path(
    DIR.OUTPUT.PROJECT,
    "geobr"
  ),
  recursive = TRUE,
  showWarnings = FALSE
)

# ---------------------------------
# OUTPUT DIRECTORIES
# ---------------------------------

DIR.FIGURES <- file.path(
  DIR.OUTPUT.PROJECT,
  "figures"
)

DIR.TABLES <- file.path(
  DIR.OUTPUT.PROJECT,
  "tables"
)


dir.create(
  DIR.FIGURES,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  DIR.TABLES,
  recursive = TRUE,
  showWarnings = FALSE
)


# ---------------------------------
# BILLING
# ---------------------------------
BD.BILLING.PROJECT.ID <- Sys.getenv("BD_BILLING_PROJECT_ID", unset = "")
if (nzchar(BD.BILLING.PROJECT.ID)) {
  basedosdados::set_billing_id(BD.BILLING.PROJECT.ID)
}


# ---------------------------------
# GENERAL PARAMETERS
# ---------------------------------

anos <- 2015:2025 
bimestre <- 6
tipo_demonstrativo <- "RREO"
anexo <- "RREO-Anexo 02" 
url_base <- "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/rreo"

# Respecting 1 req/seg API link (SICONFI)
throttle_sec <- 1


# ---------------------------------
# FUNCTIONS
# ---------------------------------
source("functions.R")


cnaes_cultura <- c(
  
  "9001901", "9001902","9001903",
  "9001904","9002701", "9003500", 
  "5911101", "5911102","5912001", 
  "5912002", "5920100","9002101",
  "9002102","9002103","9102001",
  "9102100","9102301", "9102302"
)

cnaes_audiovisual <- c(
  
  "5911101","5911102","5912001",
  "5912002","5920100"
)

cnaes_outras_artes <- c(
  
  "9001901","9001902","9001903",
  "9001904","9002701","9003500",
  "9002101","9002102",
  "9002103","9102001","9102100",
  "9102301","9102302"
)

if (SCOPE == "cultura") {
  cnaes_scope <- cnaes_cultura
} else if (SCOPE == "audiovisual") {
  cnaes_scope <- cnaes_audiovisual
} else if (SCOPE == "outras_artes") {
  cnaes_scope <- cnaes_outras_artes
} else {
  stop("SCOPE inválido.")
}
# ==========================================================
# REFERENCE VECTORS
# ==========================================================

ufs_brasil <- c(
  "AC","AL","AM","AP","BA","CE","DF","ES","GO","MA",
  "MG","MS","MT","PA","PB","PE","PI","PR","RJ","RN",
  "RO","RR","RS","SC","SE","SP","TO"
)

ordenar_ufs <- function(x) {
  factor(
    x,
    levels = rev(ufs_brasil)
  )
}

# ==========================================================
# # PROJECT VISUAL IDENTITY --------------------------------
# ==========================================================

# ---------------------------------
# GGPLOT THEMES (FIGURES)
# ---------------------------------

cor_principal  <- "#C97B63"
cor_secundaria <- "#E3B29B"
cor_escura     <- "#8B5E3C"
fonte_lpg <- "Arial"

tema_lpg <- ggplot2::theme_minimal(base_size = 18, base_family = fonte_lpg) +
  ggplot2::theme(
    panel.grid.major.y = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    plot.title = ggplot2::element_text(
      hjust = .5,
      face = "bold",
      size = 28
    ),
    plot.subtitle = ggplot2::element_text(
      hjust = .5,
      size = 18
    ),
    plot.caption = ggplot2::element_text(
      hjust = 0,
      face = "italic",
      size = 11
    ),
    axis.title = ggplot2::element_blank()
  )

escala_lpg <- function() {
  scale_fill_manual(
    values = c(
      cor_principal,
      cor_secundaria,
      cor_escura
    )
  )
}
# ---------------------------------
# GT THEMES (TABLES)
# ---------------------------------

tema_gt_descritiva <- function(gt_tbl) {
  
  gt_tbl %>%
    
    tab_style(
      style = list(
        cell_fill(color = cor_principal),
        cell_text(
          color = "white",
          weight = "bold",
          size = "18px"
        )
      ),
      locations = cells_title()
    ) %>%
    
    opt_vertical_padding(
      scale = 1.2
    ) %>%
    
    tab_options(
      table.border.top.width = px(0),
      table.border.bottom.width = px(0),
      column_labels.border.bottom.color = "#dddddd",
      table.font.size = px(14),
      table.font.names = fonte_lpg
    )
}

# ---------------------------------
# EQUATION THEMES (REGRESSIONS)
# ---------------------------------
plot_equation <- function(
    reg_number,
    subtitle,
    equations,
    output_file,
    fonte = fonte_lpg,
    width = 10,
    height = 2
) {
  
  n_eq <- length(equations)
  
  if (n_eq == 1) {
    
    y_eq <- 0.55
    
  } else {
    
    y_eq <- seq(
      from = 0.60,
      to = 0.40,
      length.out = n_eq
    )
    
  }
  
  p <- ggplot() +
    
    annotate(
      "label",
      x = -0.55,
      y = 0.82,
      label = paste("MODELO", reg_number),
      fill = "black",
      color = "white",
      fontface = "bold",
      size = 6
    ) +
    
    annotate(
      "text",
      x = -0.25,
      y = 0.82,
      label = subtitle,
      size = 5,
      fontface = "bold",
      hjust = 0
    )
  
  for(i in seq_along(equations)) {
    
    p <- p +
      annotate(
        "text",
        x = 0,
        y = y_eq[i],
        label = equations[i],
        parse = TRUE,
        size = 6.5
      )
    
  }
  
  p <- p +
    
    coord_cartesian(
      xlim = c(-1, 1),
      ylim = c(0.25, 0.95)
    ) +
    
    theme_void(
      base_family = fonte
    )
  
  ggsave(
    filename = output_file,
    plot = p,
    width = width,
    height = height,
    bg = "white"
  )
  
  invisible(p)
  
}
# END OF SCRIPT --------------------------------------------------------------------------------------------------------------------------------------

