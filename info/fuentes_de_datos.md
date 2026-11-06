# Fuentes de datos del proyecto

## Llegadas internacionales de turistas

- **Archivo:** `data/llegadas_costarica.xlsx`
- **Cobertura:** enero 2013 a diciembre 2025 (156 observaciones mensuales)
- **Columnas:** `anio`, `mes`, `llegadas`
- **Fuente:** Instituto Costarricense de Turismo (ICT), *Anuario Estadístico de Turismo*,
  sección de llegadas internacionales 2009-2025. El ICT elabora la serie con registros
  de la Dirección General de Migración y Extranjería.
- **Extracción:** los datos se publican en PDF. Se extrajeron con el paquete `pdftools`
  de R, usando `pdf_data()` para recuperar las coordenadas de cada elemento y
  reconstruir las filas de las tablas.

## Visitas a áreas silvestres protegidas

- **Archivo:** `data/visitas_areas_silvestres.xlsx`
- **Cobertura:** enero 2013 a diciembre 2024 (144 observaciones mensuales)
- **Columnas:** `anio`, `mes`, `residentes`, `no_residentes`, `total`
- **Fuente:** ICT, indicador de visitas a áreas silvestres protegidas, elaborado con
  datos de la Gerencia de Áreas Silvestres Protegidas del SINAC.
- **Extracción:** mismo procedimiento que la serie anterior.

## Advertencias de uso

- Los meses vienen escritos en español. La base de llegadas usa "Setiembre" y la de
  áreas silvestres "Septiembre". Hay que unificarlos antes de cruzarlas o se pierde un
  mes por año sin que nada avise.
- La ventana común a ambas bases es 2013-2024, y es la que se usa en el análisis conjunto.
- Las llegadas cuentan eventos de entrada, no personas: quien entra dos veces en el año
  cuenta dos veces.
