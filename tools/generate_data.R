# Генерация демонстрационных данных для смешанных моделей качества.
# Запуск из корня проекта: Rscript tools/generate_data.R

set.seed(42)

out_dir <- if (dir.exists("data")) "data" else "."
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

n_items <- 200L
n_founders <- 50L
n_markers <- 60L
n_typed <- 80L
n_factories <- 3L
sigma_a <- 1.0
sigma_e <- 1.5
sigma_factory <- 0.45
factory_levels <- c("Завод_А", "Завод_Б", "Завод_В")

simulate_lineage <- function(n_items, n_founders) {
  lin <- data.frame(item_id = seq_len(n_founders), parent_a = 0L, parent_b = 0L)
  next_id <- n_founders + 1L
  while (nrow(lin) < n_items) {
    n_new <- min(20L, n_items - nrow(lin))
    parents <- lin$item_id
    pa <- sample(parents, n_new, replace = TRUE)
    pb <- sample(parents, n_new, replace = TRUE)
    clash <- pa == pb
    while (any(clash)) {
      pb[clash] <- sample(parents, sum(clash), replace = TRUE)
      clash <- pa == pb
    }
    lin <- rbind(
      lin,
      data.frame(
        item_id = next_id:(next_id + n_new - 1L),
        parent_a = as.integer(pa),
        parent_b = as.integer(pb)
      )
    )
    next_id <- next_id + n_new
  }
  lin
}

simulate_true <- function(lineage, sigma_a) {
  n <- nrow(lineage)
  tv <- setNames(numeric(n), lineage$item_id)
  for (i in seq_len(n)) {
    pa <- lineage$parent_a[i]
    pb <- lineage$parent_b[i]
    if (pa == 0 && pb == 0) {
      tv[i] <- rnorm(1, 0, sigma_a)
    } else {
      parent_mean <- 0.5 * tv[as.character(pa)] + 0.5 * tv[as.character(pb)]
      tv[i] <- parent_mean + rnorm(1, 0, sigma_a * sqrt(0.5))
    }
  }
  as.numeric(tv)
}

simulate_panel <- function(lineage, n_markers) {
  n <- nrow(lineage)
  M <- matrix(NA_integer_, n, n_markers)
  rownames(M) <- lineage$item_id
  for (j in seq_len(n_markers)) {
    p <- runif(1, 0.2, 0.5)
    for (i in seq_len(n)) {
      pa <- lineage$parent_a[i]
      pb <- lineage$parent_b[i]
      if (pa == 0 && pb == 0) {
        M[i, j] <- rbinom(1, 2, p)
      } else {
        M[i, j] <- rbinom(1, 1, M[as.character(pa), j] / 2) +
          rbinom(1, 1, M[as.character(pb), j] / 2)
      }
    }
  }
  M
}

lineage <- simulate_lineage(n_items, n_founders)
true_value <- simulate_true(lineage, sigma_a)

line_age <- rnorm(n_items)
batch_mass <- rnorm(n_items)
batch_no <- rnorm(n_items)
batch_size <- rnorm(n_items)
age <- rnorm(n_items)
event_season <- sample(c("winter", "spring", "summer", "autumn"), n_items, replace = TRUE)
event_year <- sample(2022:2024, n_items, replace = TRUE)
factory <- sample(factory_levels, n_items, replace = TRUE, prob = c(0.42, 0.35, 0.23))
factory_eff <- rnorm(n_factories, 0, sigma_factory)[match(factory, factory_levels)]

trait <- 0.25 * line_age + 0.3 * batch_mass + 0.15 * batch_no +
  0.1 * batch_size + 0.2 * age + true_value + factory_eff + rnorm(n_items, 0, sigma_e)
trait_process <- 0.4 * true_value + 0.2 * line_age + rnorm(n_items, 0, 1.2)
trait_product <- 0.5 * true_value - 0.15 * batch_mass + rnorm(n_items, 0, 1.1)

measurements <- data.frame(
  item_id = lineage$item_id,
  line_age, batch_mass, batch_no, batch_size, age,
  event_season, event_year, factory,
  trait, trait_process, trait_product, true_value,
  stringsAsFactors = FALSE
)

M_all <- simulate_panel(lineage, n_markers)
typed_ids <- tail(lineage$item_id, n_typed)
markers <- data.frame(
  item_id = typed_ids,
  panel = apply(M_all[as.character(typed_ids), , drop = FALSE], 1, paste0, collapse = ""),
  row.names = NULL,
  stringsAsFactors = FALSE
)

reference <- data.frame(
  item_id = measurements$item_id,
  true_value = measurements$true_value,
  rel_true = pmin(0.99, pmax(0.05, 1 / (1 + abs(measurements$true_value))))
)

start <- as.Date("2022-01-01")
date_in <- start + sample(0:900, n_items, replace = TRUE)
stay <- pmax(round(rgamma(n_items, 4, scale = 40)), 20)
date_out <- as.Date(ifelse(runif(n_items) < 0.28, NA, as.character(date_in + stay)))
inventory <- data.frame(
  item_id = lineage$item_id,
  date_in = as.character(date_in),
  date_out = ifelse(is.na(date_out), NA_character_, as.character(date_out)),
  stringsAsFactors = FALSE
)

write.csv(lineage, file.path(out_dir, "lineage.csv"), row.names = FALSE)
write.csv(measurements, file.path(out_dir, "measurements.csv"), row.names = FALSE)
write.csv(markers, file.path(out_dir, "markers.csv"), row.names = FALSE)
write.csv(reference, file.path(out_dir, "reference.csv"), row.names = FALSE)
write.csv(inventory, file.path(out_dir, "inventory.csv"), row.names = FALSE)

message("Wrote ", out_dir)
