output "bucket" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.datos.id
}

output "region" {
  description = "Region del despliegue"
  value       = var.region
}

output "base_datos" {
  description = "Base de datos de Glue"
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla" {
  description = "Tabla externa de Glue"
  value       = aws_glue_catalog_table.entregas.name
}

output "workgroup" {
  description = "Workgroup de Athena"
  value       = aws_athena_workgroup.entregas.name
}

output "ubicacion_datos" {
  description = "Prefijo S3 donde se cargan los CSV"
  value       = "s3://${aws_s3_bucket.datos.id}/${var.prefijo_datos}"
}

output "ubicacion_resultados" {
  description = "Prefijo S3 donde Athena guarda los resultados"
  value       = "s3://${aws_s3_bucket.datos.id}/${var.prefijo_resultados}"
}
