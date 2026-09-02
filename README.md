# Оценка племенной ценности: rrBLUP и somer

Проект на **R**: пять Jupyter-ноутбуков. По демонстрационным данным они считают BLUP-оценки племенной ценности (EBV) — по родословной, с геномной матрицей и со случайным эффектом хозяйства — и сравнивают rrBLUP, somer и BLUPF90.

Ячейки уже выполнены: таблицы и графики сохранены внутри `.ipynb`.

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
├── r_blup.Rproj                   проект R / RStudio
├── 01_rrblup_pedigree.ipynb       pedigree BLUP (rrBLUP, матрица A)
├── 02_rrblup_ssgblup.ipynb        ssGBLUP (rrBLUP, матрица H)
├── 03_rrblup_farm_effect.ipynb    ssGBLUP плюс случайный эффект хозяйства
├── 04_somer.ipynb                 смешанная модель в somer (`mmes`)
├── 05_methods_comparison.ipynb    производительность и сравнение методов
├── data/
│   ├── pedigree.csv               animal, sire, dam
│   ├── phenotypes.csv             признак, фиксированные эффекты, tbv
│   ├── genotypes.csv              SNP-строка у части животных
│   └── estimations.csv            эталон: progenes = TBV
└── tools/
    ├── generate_data.R            синтетические CSV в data/
    ├── execute_notebooks.R        прогон всех ноутбуков
    ├── execute_one_notebook.R     выполнение одного ноутбука
    └── merge_notebook_outputs.py  вшивка вывода в .ipynb
```

Читать по номерам: `01` → `05`. Каждый файл начинается с блока **«О документе»**: источник данных, цель, короткий результат.

---

## Что внутри отчётов

| Файл | Вопрос | Данные | Методы |
|---|---|---|---|
| [`01_rrblup_pedigree.ipynb`](01_rrblup_pedigree.ipynb) | Как оценить EBV только по родословной? | [`data/pedigree.csv`](data/pedigree.csv), [`data/phenotypes.csv`](data/phenotypes.csv) | A-матрица, `mixed.solve`, SE, reliability |
| [`02_rrblup_ssgblup.ipynb`](02_rrblup_ssgblup.ipynb) | Как учесть и родословную, и SNP? | + [`data/genotypes.csv`](data/genotypes.csv) | матрицы A, M, G, H; `mixed.solve` |
| [`03_rrblup_farm_effect.ipynb`](03_rrblup_farm_effect.ipynb) | Как добавить случайный эффект фермы? | то же + `economy` | две Z-матрицы, блочная K |
| [`04_somer.ipynb`](04_somer.ipynb) | Та же модель формулой `mmes`? | то же | `vsm(ism(animal), Gu = H)` |
| [`05_methods_comparison.ipynb`](05_methods_comparison.ipynb) | Согласованы ли rrBLUP, somer и эталон? | `phenotypes.csv`, `pedigree.csv` | Спирмен, Манна–Уитни, Бланд–Альтман |

### Таблицы

| Файл | Содержание |
|---|---|
| `pedigree.csv` | `animal`, `sire`, `dam` (у основателей родители = 0) |
| `phenotypes.csv` | признак `trait`, фиксированные эффекты, хозяйство, истинная `tbv` |
| `genotypes.csv` | SNP-строка `gen` у части животных (`nom_osn`) |
| `estimations.csv` | эталон для сравнения: `progenes` = TBV |

---

## Как пересобрать

Нужны **R 4.x**, пакеты ниже и **Python 3** (`json`).

```r
install.packages(c(
  "rrBLUP", "AGHmatrix", "pedigreeTools", "sommer",
  "dplyr", "tidyr", "stringr", "e1071", "ggplot2",
  "knitr", "Matrix", "jsonlite", "evaluate", "base64enc"
))
```

Из корня репозитория:

```bash
Rscript tools/generate_data.R
Rscript tools/execute_notebooks.R
```

Первая команда пишет CSV в `data/`. Вторая заново выполняет все ячейки и сохраняет вывод в ноутбуках.

Демо-данные синтетические (`set.seed(42)`), чтобы репозиторий был самодостаточным. Скрипт генерации можно заменить своими выгрузками с теми же именами столбцов.

---

## Единый стиль отчётов

- Jupyter Notebook, ядро R.
- Русские заголовки, английские имена переменных в обратных кавычках.
- В начале каждого файла — паспорт отчёта, в конце — короткое заключение.
