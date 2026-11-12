variable "region" {
  description = "Region de AWS donde se despliega el ejercicio"
  type        = string
  default     = "us-east-1"
}

variable "prefijo_bucket" {
  description = "Prefijo del nombre del bucket. Se le agrega el id de la cuenta para que sea unico en todo S3"
  type        = string
  default     = "de-aws-examen-entregas"
}

variable "prefijo_datos" {
  description = "Prefijo del bucket donde van los CSV"
  type        = string
  default     = "entregas/"
}

variable "prefijo_resultados" {
  description = "Prefijo del bucket donde Athena escribe los resultados"
  type        = string
  default     = "resultados-athena/"
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos de Glue"
  type        = string
  default     = "examen_entregas"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa"
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena"
  type        = string
  default     = "examen-entregas"
}

variable "fecha_inicio" {
  description = "Primera fecha proyectada (incluida)"
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin" {
  description = "Ultima fecha proyectada (incluida)"
  type        = string
  default     = "2026-10-03"
}
