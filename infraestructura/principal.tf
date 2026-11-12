terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "actual" {}

locals {
  nombre_bucket = "${var.prefijo_bucket}-${data.aws_caller_identity.actual.account_id}"
}

# ---------------------------------------------------------------
# 1. Bucket S3 privado
# ---------------------------------------------------------------
resource "aws_s3_bucket" "datos" {
  bucket = local.nombre_bucket

  # permite que terraform destroy borre el bucket aunque tenga CSV y resultados dentro
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket = aws_s3_bucket.datos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------
# 2. Prefijos separados (objetos vacios que solo marcan la "carpeta")
# ---------------------------------------------------------------
resource "aws_s3_object" "prefijo_datos" {
  bucket  = aws_s3_bucket.datos.id
  key     = var.prefijo_datos
  content = ""
}

resource "aws_s3_object" "prefijo_resultados" {
  bucket  = aws_s3_bucket.datos.id
  key     = var.prefijo_resultados
  content = ""
}

# ---------------------------------------------------------------
# 3. Base de datos de Glue
# ---------------------------------------------------------------
resource "aws_glue_catalog_database" "entregas" {
  name = var.nombre_base_datos
}

# ---------------------------------------------------------------
# 4. Tabla externa con partition projection
# ---------------------------------------------------------------
resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"               = "TRUE"
    "classification"         = "csv"
    "skip.header.line.count" = "1"

    # partition projection: athena calcula las fechas en cada consulta
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio},${var.fecha_fin}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"
    "storage.location.template"      = "s3://${aws_s3_bucket.datos.id}/${var.prefijo_datos}fecha=$${fecha}/"
  }

  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.id}/${var.prefijo_datos}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name = "id_envio"
      type = "string"
    }

    columns {
      name = "ciudad"
      type = "string"
    }

    columns {
      name = "transportadora"
      type = "string"
    }

    columns {
      name = "estado"
      type = "string"
    }

    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# ---------------------------------------------------------------
# 5. Workgroup de Athena
# ---------------------------------------------------------------
resource "aws_athena_workgroup" "entregas" {
  name = var.nombre_workgroup

  # permite borrar el workgroup aunque tenga historial de consultas
  force_destroy = true

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.id}/${var.prefijo_resultados}"
    }
  }
}
