# Execute all R notebooks in separate processes and merge outputs.
# Usage from repo root: Rscript tools/execute_notebooks.R

files <- c(
  "01_lineage_blup.ipynb",
  "02_marker_blup.ipynb",
  "03_factory_effect.ipynb",
  "04_somer.ipynb",
  "05_methods_comparison.ipynb",
  "06_index_accuracy.ipynb",
  "07_dynamic_index.ipynb"
)

for (f in files) {
  message("==== ", f)
  status <- system2("Rscript", c("tools/execute_one_notebook.R", f))
  if (!identical(status, 0L)) stop("R execution failed: ", f, call. = FALSE)
  py <- system2(
    "python3",
    c("tools/merge_notebook_outputs.py", f, paste0(f, ".outputs.json"))
  )
  if (!identical(py, 0L)) stop("Merge failed: ", f, call. = FALSE)
  unlink(paste0(f, ".outputs.json"))
}

message("All notebooks executed.")
