variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "domain" {
  type = string
}

variable "github_org" {
  type = string
}

variable "admin_cidr" {
  type    = string
  default = null
}

variable "state_bucket" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "app_secret_arn" {
  type = string
}

variable "backend_image_tag" {
  type = string
}

variable "frontend_image_tag" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "r53_zone_id" {
  type = string
}
