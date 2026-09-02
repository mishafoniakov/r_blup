# Сборка HTML-отчётов в reports/
# Запуск из корня проекта: Rscript render_reports.R

pandoc_dir <- "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64"
if (!dir.exists(pandoc_dir)) {
  pandoc_dir <- "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/x86_64"
}

dir.create("reports", showWarnings = FALSE)

files <- c(
  "01_rrblup_pedigree.Rmd",
  "02_rrblup_ssgblup.Rmd",
  "03_rrblup_farm_effect.Rmd",
  "04_somer.Rmd",
  "05_methods_comparison.Rmd"
)

for (f in files) {
  message("Rendering ", f, " ...")
  script <- tempfile(fileext = ".R")
  writeLines(
    c(
      sprintf("Sys.setenv(RSTUDIO_PANDOC = '%s')", pandoc_dir),
      sprintf("rmarkdown::render('%s', output_dir = 'reports', quiet = TRUE)", f)
    ),
    script
  )
  status <- system2("Rscript", script)
  unlink(script)
  if (!identical(status, 0L)) {
    stop("Failed: ", f, call. = FALSE)
  }
  message("OK: reports/", sub("\\.Rmd$", ".html", f))
}

message("All reports rendered.")
