# Оценка племенной ценности: rrBLUP и somer

Набор из пяти R Markdown-отчётов. По демонстрационным данным они считают BLUP-оценки племенной ценности (EBV) в R — по родословной, с геномной матрицей и со случайным эффектом хозяйства — и сравнивают rrBLUP, somer и BLUPF90.

---

## Зачем это репозиторий

Проект отвечает на четыре практических вопроса:

1. Как собрать pedigree BLUP в R, если SNP ещё нет?
2. Как объединить родословную и генотипы в матрицу H (ssGBLUP)?
3. Как добавить случайный эффект хозяйства рядом с эффектом животного?
4. Совпадают ли оценки rrBLUP и somer друг с другом и с известной истинной племенной ценностью?

Тема — **генетическая оценка животных**. Данные синтетические: родословная, фенотипы, SNP и эталонная TBV.

---

## Как устроен проект

```text
.
├── README.md
├── 01_rrblup_pedigree.Rmd         pedigree BLUP (rrBLUP, матрица A)
├── 02_rrblup_ssgblup.Rmd          ssGBLUP (rrBLUP, матрица H)
├── 03_rrblup_farm_effect.Rmd      ssGBLUP плюс случайный эффект хозяйства
├── 04_somer.Rmd                   смешанная модель в somer (`mmes`)
├── 05_methods_comparison.Rmd      производительность и сравнение методов
├── data/                          CSV и скрипт генерации
├── reports/                       готовый HTML-вывод
└── render_reports.R               пересборка всех отчётов
```

Читать по номерам: `01` → `05`. Каждый файл начинается с блока **«О документе»**: источник данных, цель, короткий результат.

---

## Что внутри отчётов

| Файл | Вопрос | Данные | Методы |
|---|---|---|---|
| **01** Pedigree BLUP | Как оценить EBV только по родословной? | `pedigree.csv`, `phenotypes.csv` | A-матрица, `mixed.solve`, SE, reliability |
| **02** ssGBLUP | Как учесть и родословную, и SNP? | + `genotypes.csv` | матрицы A, M, G, H; `mixed.solve` |
| **03** Хозяйство | Как добавить случайный эффект фермы? | то же + `economy` | две Z-матрицы, блочная K |
| **04** somer | Та же модель формулой `mmes`? | то же | `vsm(ism(animal), Gu = H)` |
| **05** Сравнение | Согласованы ли rrBLUP, somer и эталон? | `phenotypes.csv`, `pedigree.csv` | Спирмен, Манна–Уитни, Бланд–Альтман |

### Таблицы

| Файл | Содержание |
|---|---|
| `pedigree.csv` | `animal`, `sire`, `dam` (у основателей родители = 0) |
| `phenotypes.csv` | признак `trait`, фиксированные эффекты, хозяйство, истинная `tbv` |
| `genotypes.csv` | SNP-строка `gen` у части животных (`nom_osn`) |
| `estimations.csv` | эталон для сравнения: `progenes` = TBV |

---

## Готовый вывод

После сборки HTML лежит в `reports/`:

- [01_rrblup_pedigree.html](reports/01_rrblup_pedigree.html)
- [02_rrblup_ssgblup.html](reports/02_rrblup_ssgblup.html)
- [03_rrblup_farm_effect.html](reports/03_rrblup_farm_effect.html)
- [04_somer.html](reports/04_somer.html)
- [05_methods_comparison.html](reports/05_methods_comparison.html)

В каждом отчёте оглавление слева, таблицы и графики уже встроены.

---

## Как пересобрать

Нужны **R 4.x**, пакеты ниже и **pandoc** (достаточно pandoc из RStudio).

```r
install.packages(c(
  "rrBLUP", "AGHmatrix", "pedigreeTools", "sommer",
  "dplyr", "tidyr", "stringr", "e1071", "ggplot2",
  "knitr", "rmarkdown", "kableExtra", "Matrix"
))
```

Из корня репозитория:

```bash
Rscript data/generate_data.R
Rscript render_reports.R
```

Первая команда пишет CSV в `data/`. Вторая собирает HTML в `reports/`.

Демо-данные синтетические (`set.seed(42)`), чтобы репозиторий был самодостаточным. Скрипт генерации можно заменить своими выгрузками с теми же именами столбцов.

---

## Единый стиль отчётов

- YAML: дата, `html_document`, тема **flatly**, оглавление слева.
- Чанки с кодом скрыты: в HTML виден результат, а не листинг.
- Русские заголовки, английские имена переменных в обратных кавычках.
- В начале каждого файла — паспорт отчёта, в конце — короткое заключение.
