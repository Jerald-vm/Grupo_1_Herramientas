# =============================================================
#  Parámetros del proyecto
#  Se centralizan acá para que todos los guiones usen los mismos
#  valores y para no tener que buscarlos dentro del código.
# =============================================================

# Rutas a las bases de datos, relativas a la carpeta cod/
RUTA_LLEGADAS <- "../data/llegadas_costarica.xlsx"
RUTA_VISITAS  <- "../data/visitas_areas_silvestres.xlsx"

# Ventana tratada como atípica por la pandemia.
# El inicio es el primer mes con caída abrupta. El final es un criterio de
# juicio del grupo: a partir de 2023 la serie se estabiliza en un nivel nuevo.
COVID_INI <- "2020 Mar"
COVID_FIN <- "2022 Dec"

# Horizonte de pronóstico, en meses
H <- 24

# Meses reservados para validar fuera de muestra
N_VALIDACION <- 24

# Órdenes fijos del ARIMA que rellena la ventana COVID.
# Se fijan a mano porque la selección automática falla con un hueco de
# 34 meses seguidos: las pruebas de raíz unitaria no funcionan con datos
# faltantes y el modelo sale vacío.
ARIMA_RELLENO <- list(pdq = c(1, 1, 1), PDQ = c(0, 1, 1))
