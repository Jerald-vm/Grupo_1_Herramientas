# =============================================================================
# Pronóstico de llegadas a Costa Rica (y visitas a áreas silvestres)
# Modelos: ETS, ARIMA, regresión (tendencia + estacionalidad) y su combinación
# =============================================================================
# install.packages(c("fpp3", "readxl", "readr"))   # solo la primera vez

library(fpp3)     # tsibble, fable, feasts, ggplot2, dplyr, lubridate...
library(readxl)
library(readr)

# ---- Parámetros que puede ajustar -------------------------------------------
RUTA_LLEGADAS <- "/home/felipe-pereirafallas/Documents/Herramientas de Ciencias de Datos I/Grupo_1_Herramientas/data/llegadas_costarica.xlsx"
RUTA_VISITAS <- "/home/felipe-pereirafallas/Documents/Herramientas de Ciencias de Datos I/Grupo_1_Herramientas/data/visitas_areas_silvestres.xlsx"
H             <- 24                   # meses a pronosticar
COVID_INI     <- yearmonth("2020 Mar")
COVID_FIN     <- yearmonth("2022 Dec") # fin del periodo atípico (ver gráfico)
N_VALIDACION  <- 24                   # últimos meses reservados para evaluar

# ---- 1. Lectura de datos ----------------------------------------------------
MESES <- c(enero = 1, febrero = 2, marzo = 3, abril = 4, mayo = 5, junio = 6,
           julio = 7, agosto = 8, setiembre = 9, septiembre = 9,
           octubre = 10, noviembre = 11, diciembre = 12)

leer_serie <- function(ruta, columna) {
  read_excel(ruta) |>
    mutate(mes_num = unname(MESES[tolower(mes)]),
           fecha   = yearmonth(make_date(anio, mes_num, 1)),
           valor   = as.numeric(.data[[columna]])) |>
    select(fecha, valor) |>
    as_tsibble(index = fecha)
}

llegadas <- leer_serie(RUTA_LLEGADAS, "llegadas")
visitas  <- leer_serie(RUTA_VISITAS,  "total")

# Revise el gráfico: ¿el periodo COVID definido arriba es razonable?
autoplot(llegadas, valor) +
  annotate("rect", xmin = as.Date(COVID_INI), xmax = as.Date(COVID_FIN),
           ymin = -Inf, ymax = Inf, alpha = 0.15, fill = "red") +
  labs(title = "Llegadas mensuales (zona roja = periodo tratado como atípico)",
       x = NULL, y = "Llegadas")

# ---- 2. Función que hace todo el flujo para una serie -----------------------
analizar <- function(datos, nombre, h = H) {
  
  # 2.1 Los meses de COVID se marcan como faltantes y se rellenan con una
  #     interpolación (ARIMA estacional), para que no distorsionen tendencia
  #     ni estacionalidad. Es un supuesto: el pronóstico describe lo que
  #     habría pasado "sin pandemia" y no un nuevo shock.
  na <- datos |>
    mutate(valor = if_else(fecha >= COVID_INI & fecha <= COVID_FIN,
                           NA_real_, valor))
  adj <- na |>
    model(arima = ARIMA(log(valor))) |>
    interpolate(na) |>
    select(fecha, valor)
  
  # 2.2 Modelos candidatos (en logaritmos: estacionalidad proporcional)
  especificar <- function(d) {
    d |>
      model(ets   = ETS(log(valor)),
            arima = ARIMA(log(valor)),
            tslm  = TSLM(log(valor) ~ trend() + season())) |>
      mutate(combinado = (ets + arima + tslm) / 3)
  }
  
  # 2.3 Validación: se entrena sin los últimos N meses y se compara con lo real
  corte  <- max(datos$fecha) - (N_VALIDACION - 1)
  fit_tr <- adj |> filter(fecha < corte) |> especificar()
  fc_val <- forecast(fit_tr, h = N_VALIDACION)
  acc <- accuracy(fc_val, datos |> select(fecha, valor)) |>
    select(.model, RMSE, MAE, MAPE) |>
    arrange(RMSE)
  mejor <- acc$.model[1]
  
  # 2.4 Reajuste con todos los datos y pronóstico a futuro
  fit <- especificar(adj)
  fc  <- forecast(fit, h = h)
  
  tabla <- fc |>
    hilo(level = 95) |>
    unpack_hilo(`95%`) |>
    as_tibble() |>
    transmute(serie = nombre, modelo = .model, fecha = as.character(fecha),
              pronostico = .mean,
              lim_inf_95 = `95%_lower`, lim_sup_95 = `95%_upper`)
  
  grafico <- autoplot(fc |> filter(.model == mejor), datos, level = c(80, 95)) +
    labs(title = paste0("Pronóstico: ", nombre, " (modelo: ", mejor, ")"),
         x = NULL, y = nombre)
  
  list(acc = acc, tabla = tabla, grafico = grafico, mejor = mejor, fit = fit)
}

# ---- 3. Ejecutar ------------------------------------------------------------
res_llegadas <- analizar(llegadas, "llegadas")
res_visitas  <- analizar(visitas,  "visitas_areas_silvestres")

cat("\n== Error en validación (llegadas), menor RMSE = mejor ==\n")
print(res_llegadas$acc)
cat("\n== Error en validación (visitas áreas silvestres) ==\n")
print(res_visitas$acc)

print(res_llegadas$grafico)
print(res_visitas$grafico)

# ---- 4. Exportar resultados -------------------------------------------------
library(writexl)   

redondear <- function(d, n = 0) mutate(d, across(where(is.numeric), ~ round(.x, n)))

tabla_todos <- bind_rows(res_llegadas$tabla, res_visitas$tabla) |> redondear()

mejores <- bind_rows(
  res_llegadas$tabla |> filter(modelo == res_llegadas$mejor),
  res_visitas$tabla  |> filter(modelo == res_visitas$mejor)) |> redondear()

validacion <- bind_rows(
  mutate(res_llegadas$acc, serie = "llegadas", .before = 1),
  mutate(res_visitas$acc,  serie = "visitas_areas_silvestres", .before = 1)) |>
  rename(modelo = .model) |>
  redondear(2)

write_xlsx(list(Mejor_modelo      = mejores,
                Todos_los_modelos = tabla_todos,
                Validacion        = validacion),
           "pronosticos.xlsx")
write_csv(tabla_todos, "pronosticos.csv")
ggsave("pronostico_llegadas.png", res_llegadas$grafico, width = 9, height = 5)
ggsave("pronostico_visitas.png",  res_visitas$grafico,  width = 9, height = 5)

