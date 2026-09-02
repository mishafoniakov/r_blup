# Генерация демонстрационных данных для отчётов по EBV.
# Запуск из корня проекта: Rscript tools/generate_data.R

set.seed(42)

out_dir <- if (dir.exists("data")) "data" else "."
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

n_animals <- 200
n_founders <- 50
n_snps <- 60
n_genotyped <- 80
n_farms <- 4
sigma_a <- 1.0
sigma_e <- 1.5
sigma_farm <- 0.45

simulate_pedigree <- function(n_animals, n_founders) {
  ped <- data.frame(animal = seq_len(n_founders), sire = 0L, dam = 0L)
  next_id <- n_founders + 1L
  while (nrow(ped) < n_animals) {
    n_new <- min(20L, n_animals - nrow(ped))
    parents <- ped$animal
    sires <- sample(parents, n_new, replace = TRUE)
    dams <- sample(parents, n_new, replace = TRUE)
    clash <- sires == dams
    while (any(clash)) {
      dams[clash] <- sample(parents, sum(clash), replace = TRUE)
      clash <- sires == dams
    }
    ped <- rbind(
      ped,
      data.frame(
        animal = next_id:(next_id + n_new - 1L),
        sire = as.integer(sires),
        dam = as.integer(dams)
      )
    )
    next_id <- next_id + n_new
  }
  ped
}

simulate_tbv <- function(pedigree, sigma_a) {
  n <- nrow(pedigree)
  tbv <- setNames(numeric(n), pedigree$animal)
  for (i in seq_len(n)) {
    sire <- pedigree$sire[i]
    dam <- pedigree$dam[i]
    if (sire == 0 && dam == 0) {
      tbv[i] <- rnorm(1, 0, sigma_a)
    } else {
      parent_mean <- 0.5 * tbv[as.character(sire)] + 0.5 * tbv[as.character(dam)]
      tbv[i] <- parent_mean + rnorm(1, 0, sigma_a * sqrt(0.5))
    }
  }
  as.numeric(tbv)
}

simulate_snps <- function(pedigree, n_snps) {
  n <- nrow(pedigree)
  M <- matrix(NA_integer_, n, n_snps)
  rownames(M) <- pedigree$animal
  for (j in seq_len(n_snps)) {
    p <- runif(1, 0.2, 0.5)
    for (i in seq_len(n)) {
      sire <- pedigree$sire[i]
      dam <- pedigree$dam[i]
      if (sire == 0 && dam == 0) {
        M[i, j] <- rbinom(1, 2, p)
      } else {
        M[i, j] <- rbinom(1, 1, M[as.character(sire), j] / 2) +
          rbinom(1, 1, M[as.character(dam), j] / 2)
      }
    }
  }
  M
}

pedigree <- simulate_pedigree(n_animals, n_founders)
tbv <- simulate_tbv(pedigree, sigma_a)

dam_age <- rnorm(n_animals)
sire_age <- rnorm(n_animals)
okot_number <- rnorm(n_animals)
okot_massa <- rnorm(n_animals)
okot_vsego <- rnorm(n_animals)
age <- rnorm(n_animals)
rodilsya_vskolki <- rnorm(n_animals)
event_season <- sample(c("winter", "spring", "summer", "autumn"), n_animals, replace = TRUE)
event_year <- sample(2022:2024, n_animals, replace = TRUE)
economy <- sample(paste0("farm", seq_len(n_farms)), n_animals, replace = TRUE)
farm_eff <- rnorm(n_farms, 0, sigma_farm)[match(economy, paste0("farm", seq_len(n_farms)))]

trait <- 0.25 * dam_age + 0.15 * sire_age + 0.3 * okot_massa +
  0.15 * okot_number + 0.1 * okot_vsego + 0.2 * age + 0.15 * rodilsya_vskolki +
  tbv + farm_eff + rnorm(n_animals, 0, sigma_e)

phenotypes <- data.frame(
  animal = pedigree$animal,
  dam_age,
  sire_age,
  okot_number,
  okot_massa,
  okot_vsego,
  age,
  rodilsya_vskolki,
  event_season,
  event_year,
  economy,
  trait,
  tbv
)

M_all <- simulate_snps(pedigree, n_snps)
geno_ids <- tail(pedigree$animal, n_genotyped)
genotypes <- data.frame(
  nom_osn = geno_ids,
  gen = apply(M_all[as.character(geno_ids), , drop = FALSE], 1, paste0, collapse = ""),
  row.names = NULL
)

# Эталон для сравнения в отчётах: истинная TBV в тех же колонках, что раньше были у BLUPF90
estimations <- data.frame(
  nom_osn = phenotypes$animal,
  progenes = phenotypes$tbv,
  rel_progenes = pmin(0.99, pmax(0.05, 1 / (1 + abs(phenotypes$tbv))))
)

write.csv(pedigree, file.path(out_dir, "pedigree.csv"), row.names = FALSE)
write.csv(phenotypes, file.path(out_dir, "phenotypes.csv"), row.names = FALSE)
write.csv(genotypes, file.path(out_dir, "genotypes.csv"), row.names = FALSE)
write.csv(estimations, file.path(out_dir, "estimations.csv"), row.names = FALSE)

message("Записано в ", out_dir, ":")
message("  pedigree.csv     — ", nrow(pedigree), " животных")
message("  phenotypes.csv   — ", nrow(phenotypes), " записей")
message("  genotypes.csv    — ", nrow(genotypes), " генотипированных, ", n_snps, " SNP")
message("  estimations.csv  — истинная TBV (progenes) для сравнения")
