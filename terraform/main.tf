resource "hcloud_network" "language_translator_network" {
  name = "language-translator-network"
  ip_range = "10.0.1.0/24"
}

resource "hcloud_network_subnet" "language_translator" {
  network_id   = hcloud_network.language_translator_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "hcloud_ssh_key" "ssh_key" {
  name = "language-translator-ssh-key"
  public_key = var.ssh_public_key
}

resource "hcloud_ssh_key" "internal_ssh_key" {
  name = "language-translator-internal-ssh-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "hcloud_volume" "language_translator_volume" {
  name = "language-translator-volume"
  size = 20
  format = "ext4"
  #delete_protection = true
  location = "hel1"

  #lifecycle {
  #  prevent_destroy = true
  #}
}

resource "hcloud_volume_attachment" "language_translator_volume_attachment" {
  volume_id = hcloud_volume.language_translator_volume.id
  server_id = hcloud_server.manager.id
  automount = true
}

resource "hcloud_server" "manager" {
  name   = "language-translator-manager"
  image  = var.image
  location = "hel1"
  server_type = var.manager_server_type
  depends_on = [hcloud_network_subnet.language_translator, tls_private_key.ssh, hcloud_ssh_key.ssh_key]

  network {
    network_id = hcloud_network.language_translator_network.id
    ip = var.manager_private_ip
  }
  
  firewall_ids = [hcloud_firewall.language_translator_manager_firewall.id, hcloud_firewall.language_translator_worker_firewall.id]

  ssh_keys = [hcloud_ssh_key.ssh_key.id, hcloud_ssh_key.internal_ssh_key.id]

  connection {
    host = self.ipv4_address
    timeout = "2m"
    private_key = "${var.ssh_private_key}"
  }

  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/root/.ssh/id_rsa"
  }

  provisioner "file" {
    content     = tls_private_key.ssh.public_key_openssh
    destination = "/root/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source = "service_account.json"
    destination = "/root/service_account.json"
  }

  provisioner "file" {
    source = ".env.prod"
    destination = "/root/.env.prod"
  }

  provisioner "file" {
    source = "rsyslog"
    destination = "/etc/logrotate.d/rsyslog"
  }

  provisioner "file" {
    source = "01-blocklist.conf"
    destination = "/etc/rsyslog.d/01-blocklist.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "docker plugin install grafana/loki-docker-driver:2.8.2 --alias loki --grant-all-permissions",
      "systemctl restart docker",
      "systemctl restart rsyslog",
      "docker swarm init --advertise-addr ${var.manager_private_ip} --data-path-port 4792",
      "docker swarm join-token worker -q > /worker_token",
      "echo PasswordAuthentication no >> /etc/ssh/sshd_config",
      "docker node update --label-add=language_translator=true language-translator-manager",
    ]
  }
}

resource "null_resource" "manager_init" {
  depends_on = [hcloud_server.manager]

  connection {
    host = hcloud_server.manager.ipv4_address
    timeout = "2m"
    private_key = "${var.ssh_private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "apt update && apt install -y jq",
      "VOLUME=$(mount -l | grep /mnt/HC_Volume_ | awk '{print $3}')",
      "if [ -n $VOLUME ]; then",
      " systemctl stop docker",
      " cp -r /var/lib/docker/* $VOLUME",
      " jq -n --arg v $VOLUME '{\"data-root\": $v}' > /etc/docker/daemon.json",
      " rm -r /var/lib/docker",
      " ln -s $VOLUME /var/lib/docker",
      " systemctl start docker",
      "fi",
      ". /root/.env.prod",
      "sudo chmod 400 /root/.ssh/id_rsa",
      "sudo chmod 400 /root/.ssh/id_rsa.pub",
      "git clone https://$GIT_TOKEN@github.com/yaboiishere/language_translator.git",
      "cp .env.prod language_translator/.env.prod",
      "cp service_account.json language_translator/service_account.json",
      "cd language_translator",
      "echo $GIT_TOKEN | docker login ghcr.io -u yaboiishere --password-stdin",
      "docker compose pull",
      "echo $PORTAINER_PASSWORD > /root/.portainer_password"
    ]
  }
}

resource "hcloud_server" "worker" {
  count = var.worker_count
  name   = "language-translator-worker-${count.index}"
  image  = var.image
  server_type = var.worker_server_type
  location = "hel1"

  network {
    network_id = hcloud_network.language_translator_network.id
  }

  depends_on = [hcloud_network_subnet.language_translator, tls_private_key.ssh, hcloud_ssh_key.ssh_key, hcloud_server.manager, null_resource.manager_init]

  firewall_ids = [hcloud_firewall.language_translator_worker_firewall.id]

  ssh_keys = [hcloud_ssh_key.ssh_key.id, hcloud_ssh_key.internal_ssh_key.id]

  connection {
    host = self.ipv4_address
    timeout = "2m"
    private_key = "${var.ssh_private_key}"
  }

  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/root/.ssh/id_rsa"
  }

  provisioner "file" {
    content     = tls_private_key.ssh.public_key_openssh
    destination = "/root/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source = ".env.prod"
    destination = "/root/.env.prod"
  }

  provisioner "file" {
    source = "service_account.json"
    destination = "/root/service_account.json"
  }

  provisioner "file" {
    source = "rsyslog"
    destination = "/etc/logrotate.d/rsyslog"
  }

  provisioner "file" {
    source = "01-blocklist.conf"
    destination = "/etc/rsyslog.d/01-blocklist.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "docker plugin install grafana/loki-docker-driver:2.8.2 --alias loki --grant-all-permissions",
      "systemctl restart docker",
      "systemctl restart rsyslog",
      "sudo chmod 400 /root/.ssh/id_rsa",
      "sudo chmod 400 /root/.ssh/id_rsa.pub",
      ". /root/.env.prod",
      "echo $GIT_TOKEN | docker login ghcr.io -u yaboiishere --password-stdin",
      "git clone https://$GIT_TOKEN@github.com/yaboiishere/language_translator.git",
      "cp .env.prod language_translator/.env.prod",
      "cp service_account.json language_translator/service_account.json",
      "sudo scp -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null root@${var.manager_private_ip}:/worker_token .",
      "cd language_translator",
      "docker swarm join --token $(cat /root/worker_token) ${var.manager_private_ip}:2377",
      "echo PasswordAuthentication no >> /etc/ssh/sshd_config"
    ]
  }

}

resource "null_resource" "manager" {
  depends_on = [null_resource.manager_init, hcloud_server.worker]

  connection {
    host = hcloud_server.manager.ipv4_address
    timeout = "2m"
    private_key = "${var.ssh_private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      ". /root/.env.prod",
      "cd language_translator",
      "export $(cat .env.prod) > /dev/null 2>&1; docker stack deploy -c docker-compose.yml --with-registry-auth language_translator",
    ]
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

terraform {
  required_version = ">= 1.4"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.35.2"
    }
  }
}

