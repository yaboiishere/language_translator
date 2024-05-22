variable "allowed_ips" {
  description = "List of allowed IPs for SSH access"
  type        = list(string)
}

variable "image" {
  description = "Hetzner Cloud image to use"
  type        = string
  default     = "docker-ce"
}

variable "manager_server_type" {
  description = "Hetzner Cloud server type for the manager"
  type        = string
  default     = "cax11"
}

variable "manager_private_ip" {
  description = "Private IP address for the manager"
  type        = string
  default     = "10.0.1.2"
}

variable "worker_server_type" {
  description = "Hetzner Cloud server type for the worker"
  type        = string
  default     = "cax11"
}

variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 0
}

variable "ssh_public_key" {
  description = "Your SSH public key"
  type        = string
}

variable "ssh_private_key" {
  description = "Your SSH private key"
  type        = string
  default     = null
  sensitive   = true
}

variable "hcloud_token" {
  sensitive = true # Requires terraform >= 0.14
}

