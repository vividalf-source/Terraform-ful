variable "region" {
  type    = string
  default = "us-east-1"
}

variable "proyecto" {
  type    = string
  default = "eduandes"
}

variable "aplicacion" {
  type    = string
  default = "biblioteca"
}

variable "responsable" {
  type    = string
  default = "vicente-vidal"
}

variable "ambiente" {
  description = "Ambiente de despliegue: dev o prod"
  type        = string
  default     = "dev"
}

variable "subredes" {
  type = map(object({
    cidr    = string
    az      = string
    publica = bool
  }))
}

variable "servidores" {
  type = map(object({
    instance_type = string
    disk_size     = number
    subred        = string
  }))
}

variable "db_password" {
  description = "Contraseña maestra de RDS"
  type        = string
  sensitive   = true
}