# Metadata ----------------------------------------------------------------
# Title: A) Prepare election data
# Purpose: Combine census and electoral data at "circuito" for BA & CABA
# Author(s): @pablocal
# Date Created: 2019-09-11
#
# Comments ----------------------------------------------------------------
# This is a combination of election data and 2010 census:
# a) Electoral data: PASO 2015, Presidential 2015, PASO 2019
# b) Censo 2010: Downloaded from http://dump.jazzido.com/CNPHV2010-RADIO/
# collected by @jazzido
#
# A) Electoral data
#
# Options and packages ----------------------------------------------------

library(tidyverse)

# A) Prepare electoral data: PRES19, PASO19, PASO15, PRES15

# A.0. Create a PRES 2019 file -----------------------------------------

## Load the files (source: https://www.resultados2019.gob.ar/)
pres19_cand_id <- read_delim("data/pres2019/descripcion_postulaciones.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # cadidate labels
pres19_reg_id <- read_delim("data/pres2019/descripcion_regiones.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # region labels
pres19_totals <- read_delim("data/pres2019/mesas_totales.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # electoral totals
pres19_cand <- read_delim("data/pres2019/mesas_agrp_politicas.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # electoral votes to candidates

## Get blank votes to compute valid and percentages
pres19_totals_pres_blank <- pres19_totals %>% 
  filter(codigo_categoria == "000100000000000",
         contador == "Voto blanco") %>% 
  select(codigo_mesa, valor) %>% 
  rename(votos_blanco = valor)

## Prepare regional identifiers
pres19_reg_id <- pres19_reg_id %>% 
  mutate(codigo_distrito = codigo_region,
         codigo_seccion = codigo_region,
         codigo_circuito = codigo_region) %>% 
  rename(name = nombre_region)

## Select party names
pres19_cand_id <- pres19_cand_id %>% 
  filter(codigo_categoria == "000100000000000") %>% 
  group_by(codigo_agrupacion) %>%
  summarise(nombre_agrupacion = first(nombre_agrupacion))

## Votes to candidature to compute total valids
pres19_cand_pres <- pres19_cand %>% 
  filter(codigo_categoria == "000100000000000") %>% 
  group_by(codigo_mesa) %>% 
  mutate(votos_candidatura = sum(votos_agrupacion)) %>%
  ungroup() 

## join files 
pres19_mesa <- pres19_cand_pres %>% 
  left_join(pres19_totals_pres_blank, by = "codigo_mesa") %>% 
  mutate(votos_validos = votos_candidatura + votos_blanco) %>%
  left_join(select(pres19_reg_id, codigo_distrito, name), by = "codigo_distrito") %>% 
  rename(name_distrito = name) %>% 
  left_join(select(pres19_reg_id, codigo_seccion, name), by = "codigo_seccion") %>% 
  rename(name_seccion = name) %>%
  left_join(pres19_cand_id, by = "codigo_agrupacion") %>% 
  select(codigo_distrito, name_distrito, codigo_seccion, name_seccion, codigo_circuito, 
         codigo_mesa, votos_blanco, votos_validos, codigo_agrupacion, nombre_agrupacion, votos_agrupacion)

## summarise file at circuito level

# blank and valid
pres19_circuito_long_totals <- pres19_mesa %>%
  group_by(codigo_circuito, codigo_mesa) %>% 
  summarise(votos_blanco = first(votos_blanco), 
            votos_validos = first(votos_validos)) %>% 
  ungroup() %>% 
  group_by(codigo_circuito) %>% 
  summarise(votos_blanco = sum(votos_blanco),
            votos_validos = sum(votos_validos)
  )

# filter for CABA and BA and match with blank and valid
pres19_circuito_long <- pres19_mesa %>%
  select(-votos_blanco, -votos_validos) %>% 
  filter(codigo_distrito %in% c("01", "02")) %>% 
  mutate(partido = recode(nombre_agrupacion, "JUNTOS POR EL CAMBIO" = "Juntos por el Cambio",
                          "FRENTE DE TODOS" = "Frente de Todos",
                          .default = "Otros")) %>% 
  group_by(codigo_circuito, partido) %>% 
  summarise(votos_candidatura = sum(votos_agrupacion)) %>%
  left_join(pres19_circuito_long_totals, by = "codigo_circuito") %>% 
  rename(id_circuito_elec = codigo_circuito) %>% 
  mutate(year = 2019) %>% 
  select(year, id_circuito_elec, votos_blanco, votos_validos, partido, votos_candidatura)


## to wide format
pres19_circuito_wide <- spread(pres19_circuito_long, key = partido, value = votos_candidatura) %>% 
  rename(pres19_cand_FdT = `Frente de Todos`,
         pres19_cand_JxC = `Juntos por el Cambio`,
         pres19_cand_Otros = Otros,
         pres19_blanco = votos_blanco,  
         pres19_validos = votos_validos) %>% 
  select(-year)

## save file  
write_rds(pres19_circuito_long, "data/Pres_2019_circuito_long.RDS")
write_rds(pres19_circuito_wide, "data/Pres_2019_circuito_wide.RDS")

# A.1. Create a PASO 2019 file -----------------------------------------

## Load the files (source: https://www.resultados2019.gob.ar/)
paso19_cand_id <- read_delim("data/paso2019/descripcion_postulaciones.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # cadidate labels
paso19_reg_id <- read_delim("data/paso2019/descripcion_regiones.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # region labels
paso19_totals <- read_delim("data/paso2019/mesas_totales.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # electoral totals
paso19_cand <- read_delim("data/paso2019/mesas_totales_agrp_politica.dsv", delim = "|") %>% 
  rename_all(str_to_lower) # electoral votes to candidates

## Get blank votes to compute valid and percentages
paso19_totals_pres_blank <- paso19_totals %>% 
  filter(codigo_categoria == "000100000000000",
         contador == "VB") %>% 
  select(codigo_mesa, valor) %>% 
  rename(votos_blanco = valor)

## Prepare regional identifiers
paso19_reg_id <- paso19_reg_id %>% 
  mutate(codigo_distrito = codigo_region,
         codigo_seccion = codigo_region,
         codigo_circuito = codigo_region) %>% 
  rename(name = nombre_region)

## Select party names
paso19_cand_id <- paso19_cand_id %>% 
  filter(codigo_categoria == "000100000000000") %>% 
  group_by(codigo_agrupacion) %>%
  summarise(nombre_agrupacion = first(nombre_agrupacion))

## Votes to candidature to compute total valids
paso19_cand_pres <- paso19_cand %>% 
  filter(codigo_categoria == "000100000000000") %>% 
  group_by(codigo_mesa) %>% 
  mutate(votos_candidatura = sum(votos_agrupacion)) %>%
  ungroup() 

## join files 
paso19_mesa <- paso19_cand_pres %>% 
  left_join(paso19_totals_pres_blank, by = "codigo_mesa") %>% 
  mutate(votos_validos = votos_candidatura + votos_blanco) %>%
  left_join(select(paso19_reg_id, codigo_distrito, name), by = "codigo_distrito") %>% 
  rename(name_distrito = name) %>% 
  left_join(select(paso19_reg_id, codigo_seccion, name), by = "codigo_seccion") %>% 
  rename(name_seccion = name) %>%
  left_join(paso19_cand_id, by = "codigo_agrupacion") %>% 
  select(codigo_distrito, name_distrito, codigo_seccion, name_seccion, codigo_circuito, 
         codigo_mesa, votos_blanco, votos_validos, codigo_agrupacion, nombre_agrupacion, votos_agrupacion)

## summarise file at circuito level

# blank and valid
paso19_circuito_long_totals <- paso19_mesa %>%
  group_by(codigo_circuito, codigo_mesa) %>% 
  summarise(votos_blanco = first(votos_blanco), 
            votos_validos = first(votos_validos)) %>% 
  ungroup() %>% 
  group_by(codigo_circuito) %>% 
  summarise(votos_blanco = sum(votos_blanco),
            votos_validos = sum(votos_validos)
  )

# filter for CABA and BA and match with blank and valid
paso19_circuito_long <- paso19_mesa %>%
  select(-votos_blanco, -votos_validos) %>% 
  filter(codigo_distrito %in% c("01", "02")) %>% 
  mutate(partido = recode(nombre_agrupacion, "JUNTOS POR EL CAMBIO" = "Juntos por el Cambio",
                          "FRENTE DE TODOS" = "Frente de Todos",
                          .default = "Otros")) %>% 
  group_by(codigo_circuito, partido) %>% 
  summarise(votos_candidatura = sum(votos_agrupacion)) %>%
  left_join(paso19_circuito_long_totals, by = "codigo_circuito") %>% 
  rename(id_circuito_elec = codigo_circuito) %>% 
  mutate(year = 2019) %>% 
  select(year, id_circuito_elec, votos_blanco, votos_validos, partido, votos_candidatura)


## to wide format
paso19_circuito_wide <- spread(paso19_circuito_long, key = partido, value = votos_candidatura) %>% 
  rename(paso19_cand_FdT = `Frente de Todos`,
         paso19_cand_JxC = `Juntos por el Cambio`,
         paso19_cand_Otros = Otros,
         paso19_blanco = votos_blanco,  
         paso19_validos = votos_validos) %>% 
  select(-year)

## save file  
write_rds(paso19_circuito_long, "data/PASO_2019_circuito_long.RDS")
write_rds(paso19_circuito_wide, "data/PASO_2019_circuito_wide.RDS")

# A.2. Create a PASO 2015 file -----------------------------------------

paso15_cand_id <- read_csv2("data/paso2015/codigosbasicospaso2015provisional/FPARTIDOS.csv") %>% 
  rename_all(str_to_lower)
paso15_cand_caba <- read_csv2("data/paso2015/presidentepaso2015provisional/FMESPR_0101.csv") %>% 
  rename_all(str_to_lower)
paso15_cand_ba <- read_csv2("data/paso2015/presidentepaso2015provisional/FMESPR_0202.csv") %>% 
  rename_all(str_to_lower)

paso15_cand <- bind_rows(paso15_cand_ba, paso15_cand_caba)

## get blank votes
paso15_blanks <- paso15_cand %>% 
  filter(`codigo votos` == 9004) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`) %>%
  summarise(blancos = sum(as.integer(votos))) 

## get valid votes
paso15_sum_votes <- paso15_cand %>% 
  filter(`codigo votos` < 9000) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`) %>%
  summarise(candidaturas = sum(as.integer(votos)))

paso15_valid <- left_join(paso15_sum_votes, paso15_blanks, 
                          by = c("codigo provincia", "codigo departamento", "codigo circuito"))

## get cand votes
paso15_cand_id <- paso15_cand_id %>% 
  mutate(`codigo votos` = as.numeric(codigo_partido)) %>% 
  select(-codigo_partido, -lista_interna, -agrupacion)

paso15_votes <- paso15_cand %>% 
  filter(`codigo votos` < 9000) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`, `codigo votos`) %>%
  summarise(candidatura = sum(as.integer(votos))) %>% 
  left_join(paso15_cand_id, by = "codigo votos") %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`, denominacion) %>%
  summarise(candidatura = sum(candidatura)) %>% 
  mutate(denominacion = recode(denominacion,
                               "ALIANZA CAMBIEMOS" = "Cambiemos",
                               "ALIANZA FRENTE PARA LA VICTORIA" = "Frente Para la Victoria" ,
                               "ALIANZA UNIDOS POR UNA NUEVA ALTERNATIVA (UNA)" =  "UNA",	
                               .default = "Otros")) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`, denominacion) %>%
  summarise(candidatura = sum(candidatura)) %>% 
  rename(partido = denominacion,
         votos_candidatura = candidatura) %>% 
  ungroup()

## join files semi-long
paso15_circuito_long <- paso15_votes %>%
  left_join(paso15_valid, by = c("codigo provincia", "codigo departamento", "codigo circuito")) %>% 
  mutate(year = 2015,
         ln_circuito = str_length(`codigo circuito`),
         zeroes = case_when(
           ln_circuito == 2 ~ "0000",
           ln_circuito == 3 ~ "000",
           ln_circuito == 4 ~ "00",
           ln_circuito == 5 ~ "0",
           ln_circuito == 6 ~ ""
         ),
         id_circuito_elec = paste0(`codigo provincia`, `codigo departamento`, zeroes, `codigo circuito`),
         votos_validos = blancos + candidaturas) %>% 
  rename(votos_blanco = blancos) %>% 
  select(year, id_circuito_elec, partido, votos_blanco, votos_validos, votos_candidatura)

## join files wide
paso15_circuito_wide <- spread(paso15_circuito_long, key = partido, value = votos_candidatura) %>% 
  rename(paso15_cand_FPV = `Frente Para la Victoria`,
         paso15_cand_Cam = Cambiemos,
         paso15_cand_UNA = UNA,
         paso15_cand_Otros = Otros,
         paso15_blanco = votos_blanco,  
         paso15_validos = votos_validos) %>% 
  select(-year)

## join files wide
write_rds(paso15_circuito_long, "data/PASO_2015_circuito_long.RDS")
write_rds(paso15_circuito_wide, "data/PASO_2015_circuito_wide.RDS")

# A.3. Create a presi 2015 file -----------------------------------------

pres15_cand_id <- read_csv2("data/paso2015/codigosbasicospaso2015provisional/FPARTIDOS.csv") %>% 
  rename_all(str_to_lower)
pres15_cand_caba <- read_csv2("data/pres2015/FMESPR_0101.csv") %>% 
  rename_all(str_to_lower)
pres15_cand_ba <- read_csv2("data/pres2015/FMESPR_0202.csv") %>% 
  rename_all(str_to_lower)

pres15_cand <- bind_rows(pres15_cand_ba, pres15_cand_caba)

## get blank votes
pres15_blanks <- pres15_cand %>% 
  filter(`codigo votos` == 9004) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`) %>%
  summarise(blancos = sum(as.integer(votos))) 

## get valid votes
pres15_sum_votes <- pres15_cand %>% 
  filter(`codigo votos` < 9000) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`) %>%
  summarise(candidaturas = sum(as.integer(votos)))

pres15_valid <- left_join(pres15_sum_votes, pres15_blanks, by = c("codigo provincia", "codigo departamento", "codigo circuito"))

## get cand votes
pres15_cand_id <- pres15_cand_id %>% 
  mutate(`codigo votos` = as.numeric(codigo_partido)) %>% 
  select(-codigo_partido, -lista_interna, -agrupacion)

pres15_votes <- pres15_cand %>% 
  filter(`codigo votos` < 9000) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`, `codigo votos`) %>%
  summarise(candidatura = sum(as.integer(votos))) %>% 
  mutate(`codigo votos` = as.numeric(`codigo votos`)) %>% 
  left_join(pres15_cand_id, by = "codigo votos") %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`, denominacion) %>%
  summarise(candidatura = sum(candidatura)) %>% 
  mutate(denominacion = recode(denominacion,
                               "ALIANZA CAMBIEMOS" = "Cambiemos",
                               "ALIANZA FRENTE PARA LA VICTORIA" = "Frente Para la Victoria" ,
                               "ALIANZA UNIDOS POR UNA NUEVA ALTERNATIVA (UNA)" =  "UNA",	
                               .default = "Otros")) %>% 
  group_by(`codigo provincia`, `codigo departamento`, `codigo circuito`, denominacion) %>%
  summarise(candidatura = sum(candidatura)) %>% 
  rename(partido = denominacion,
         votos_candidatura = candidatura) %>% 
  ungroup()

## join files semi-long
pres15_circuito_long <- pres15_votes %>%
  left_join(pres15_valid, by = c("codigo provincia", "codigo departamento", "codigo circuito")) %>% 
  mutate(year = 2015,
         ln_circuito = str_length(`codigo circuito`),
         zeroes = case_when(
           ln_circuito == 2 ~ "0000",
           ln_circuito == 3 ~ "000",
           ln_circuito == 4 ~ "00",
           ln_circuito == 5 ~ "0",
           ln_circuito == 6 ~ ""
         ),
         id_circuito_elec = paste0(`codigo provincia`, `codigo departamento`, zeroes, `codigo circuito`),
         votos_validos = blancos + candidaturas) %>% 
  rename(votos_blanco = blancos) %>% 
  select(year, id_circuito_elec, partido, votos_blanco, votos_validos, votos_candidatura)

## transform to wide format
pres15_circuito_wide <- spread(pres15_circuito_long, key = partido, value = votos_candidatura) %>% 
  rename(pres15_cand_FPV = `Frente Para la Victoria`,
         pres15_cand_Cam = Cambiemos,
         pres15_cand_UNA = UNA,
         pres15_cand_Otros = Otros,
         pres15_blanco = votos_blanco,  
         pres15_validos = votos_validos) %>% 
  select(-year)

## save files
write_rds(pres15_circuito_long, "data/Pres_2015_circuito_long.RDS")
write_rds(pres15_circuito_wide, "data/Pres_2015_circuito_wide.RDS")
