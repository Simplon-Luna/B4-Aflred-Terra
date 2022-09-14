variable "rg" {
  default = "S1"
}

variable "location" {
  default = "westus"
}

variable "subdomain" {
  default = "votingapp-${var.rg}"
}

data "cloudinit_config" "cloud-init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("../cloud-init.yml", {REDIS_HOST = azurerm_redis_cache.redis.hostname,
                                                      REDIS_PWD = azurerm_redis_cache.redis.primary_access_key})
  }
}
