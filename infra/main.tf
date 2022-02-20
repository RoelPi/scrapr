terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

# Authentication
provider "tls" {
  // no config needed
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "../.keys/.ssh/gp-machine"
  file_permission = "0600"
}

provider "google" {
  credentials = file("../.keys/gcp-terraform.json")
  project     = "scrape2h"
  region      = "europe-west1"
  zone        = "europe-west1-b"
}

data "google_client_openid_userinfo" "me" {}

# Networking
resource "google_compute_network" "scrape2h_network" {
  name = "scrape2h-network"
}

resource "google_compute_address" "gp_machine_static_external_ip" {
  name         = "gp-machine-static-external-ip"
  address_type = "EXTERNAL"
  region       = "europe-west1"
}

resource "google_compute_address" "gp_machine_static_internal_ip" {
  name = "gp-machine-static-internal-ip"
  /*subnetwork   = google_compute_subnetwork.scrape2h_subnet.id*/
  address_type = "INTERNAL"
  region       = "europe-west1"
}

resource "google_compute_firewall" "allow_ssh" {
  name          = "allow-ssh"
  network       = google_compute_network.scrape2h_network.name
  target_tags   = ["allow-ssh"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Compute Engine
resource "google_compute_instance" "gp_machine" {
  name         = "gp-machine"
  machine_type = "e2-standard-2"
  zone         = "europe-west1-b"
  tags         = ["allow-ssh"]

  service_account {
    email  = "397473106270-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  network_interface {
    network = google_compute_network.scrape2h_network.name
    # subnetwork = google_compute_subnetwork.scrape2h_subnet.name
    network_ip = google_compute_address.gp_machine_static_internal_ip.address
    access_config {
      nat_ip = google_compute_address.gp_machine_static_external_ip.address
    }
  }

  boot_disk {
    initialize_params {
      type  = "pd-standard"
      size  = "20"
      image = "debian-10-buster-v20220118"
    }
  }

  metadata = {
    ssh-keys = "roel:${tls_private_key.ssh.public_key_openssh}"
  }
}

/*
resource "random_string" "random_suffix" {
  length  = 3
  special = false
  lower   = true
  upper   = false
  keepers = {
    instance_ip = "${google_compute_address.gp_machine_static_external_ip.address}"
  }
}

# Cloud SQL
resource "google_sql_database_instance" "gp_database" {
  name             = "gp-database-${random_string.random_suffix.result}"
  database_version = "POSTGRES_13"
  region           = "europe-west1"

  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-custom-1-3840" # You can't use the new machine types. Use custom: https://cloud.google.com/sql/docs/mysql/create-instance#machine-types

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = google_compute_instance.gp_machine.name
        value = google_compute_address.gp_machine_static_external_ip.address
      }
    }
  }
}

resource "google_sql_user" "u_airflow" {
  name     = "u-airflow"
  instance = google_sql_database_instance.gp_database.name
  password = "aiRfl0wpAssW0rd!&#"
}

*/
output "gp_machine_static_external_ip" {
  value = google_compute_address.gp_machine_static_external_ip.address
}

/*
output "gp_database_ip" {
  value = google_sql_database_instance.gp_database.ip_address.0.ip_address
}

output "gp_database_name" {
  value = google_sql_database_instance.gp_database.name
}

output "gp_database_user" {
  value = google_sql_user.u_airflow.name
}

output "gp_database_password" {
  sensitive = true
  value     = google_sql_user.u_airflow.password
}
*/