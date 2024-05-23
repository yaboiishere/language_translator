resource "hcloud_firewall" "language_translator_worker_firewall" {
  name = "language-translator-worker-firewall"
  #SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port = "22"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
}

resource "hcloud_firewall" "language_translator_manager_firewall" {
  name = "language-translator-manager-firewall"
  # Grafana
  rule {
    direction  = "in"
    protocol   = "tcp"
    port = "3000"
    source_ips = var.allowed_ips
  }

  # Haproxy stats
  rule {
    direction  = "in"
    protocol   = "tcp"
    port = "8404"
    source_ips = var.allowed_ips
  }

  # Postgres
  rule {
    direction  = "in"
    protocol   = "tcp"
    port = "5432"
    source_ips = var.allowed_ips
  }

  # HTTP
  rule {
    direction  = "in"
    protocol   = "tcp"
    port = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # HTTPS
  rule {
    direction  = "in"
    protocol   = "tcp"
    port = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Portainer
  rule {
    direction  = "in"
    protocol   = "tcp"
    port = "9443"
    source_ips = var.allowed_ips
  }
}


