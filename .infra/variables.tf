# Definición de usuario y contraseña de PostgreSQL
variable "cloud_sql_user" {
  type    = string
  default = "TU_USUARIO_DE_POSTGRES"
}

variable "cloud_sql_password" {
  type    = string
  default = "TU_PASSWORD_DE_POSTGRES"
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "gcs_bucket_name" {
  type    = string
  default = "flas-app"
}

variable "gcs_zip_file_name" {
  type    = string
  default = "flask-app.zip"
}

variable "gcs_zip_folder" {
  type    = string
  default = "flask-app"
}

variable "instance_zone" {
  type = string
  default = "us-east1-b"
}