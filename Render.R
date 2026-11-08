# render.R
# Renderiza el informe en PDF y lo deja en la carpeta res/.
#
# Uso: abrir una terminal en la carpeta raiz del proyecto (la que contiene
# cod/, data/ y res/) y ejecutar:
#
#   Rscript render.R
#
# Requisitos: Quarto, una distribucion de LaTeX (por ejemplo TinyTeX:
# quarto install tinytex) y los paquetes de R fpp3, readxl y knitr.

qmd <- file.path("cod", "Grupo_1_HerramientasDatosI_2026.qmd")
salida <- "res"

if (!file.exists(qmd)) {
  stop("No encuentro ", qmd, ". Ejecute este script desde la carpeta raiz ",
       "del proyecto (directorio actual: ", getwd(), ").")
}

if (Sys.which("quarto") == "") {
  stop("No se encontro Quarto. Instalelo desde https://quarto.org")
}

# Renderiza. El PDF queda junto al .qmd, en cod/
estado <- system2("quarto", c("render", shQuote(qmd), "--to", "pdf"))
if (estado != 0) {
  stop("Fallo el render del qmd. Revise los mensajes de arriba.")
}

# Mueve el PDF a res/
pdf <- sub("\\.qmd$", ".pdf", qmd)
if (!file.exists(pdf)) {
  stop("El render termino, pero no se genero ", pdf)
}

dir.create(salida, showWarnings = FALSE)
if (file.copy(pdf, salida, overwrite = TRUE)) {
  file.remove(pdf)
  message("Listo: ", file.path(salida, basename(pdf)))
} else {
  stop("No se pudo copiar el PDF a ", salida, ". Cierre el PDF si lo tiene abierto.")
}