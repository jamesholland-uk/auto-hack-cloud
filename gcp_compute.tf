/*
 * Copyright 2018 Palo Alto Networks
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/*
 * Terraform compute resources for GCP.
 * Acquire all zones and choose one randomly.
 */

data "google_compute_zones" "available" {
  region = "${var.gcp_region}"
}

/*
 *  Networks and subnetworks
 */

resource "google_compute_network" "mgmt" {
    name                    = "mgmt"
    auto_create_subnetworks = false
  }
resource "google_compute_subnetwork" "mgmt-net" {
  name          = "mgmt-net"
  ip_cidr_range = "192.168.0.0/24"
  region        = "europe-west2"
  network       = "mgmt"
  depends_on = ["google_compute_network.mgmt"]
}

resource "google_compute_network" "inside" {
    name                    = "inside"
    auto_create_subnetworks = false
  }
resource "google_compute_subnetwork" "inside-net" {
  name          = "inside-net"
  ip_cidr_range = "10.10.10.0/24"
  region        = "europe-west2"
  network       = "inside"
  depends_on = ["google_compute_network.inside"]
}

resource "google_compute_network" "outside" {
    name                    = "outside"
    auto_create_subnetworks = false
  }

resource "google_compute_subnetwork" "outside-net" {
  name          = "outside-net"
  ip_cidr_range = "172.16.0.0/24"
  region        = "europe-west2"
  network       = "outside"
  depends_on = ["google_compute_network.outside"]
}

/*
 *  Public IP addresses
 */

resource "google_compute_address" "mgmt-pip" {
  name = "mgmt-pip"
  address_type = "EXTERNAL"
  region = "europe-west2"
}

resource "google_compute_address" "outside-pip" {
  name = "outside-pip"
  address_type = "EXTERNAL"
  region = "europe-west2"
}

/*
 *  PAN-OS Next-generation Firewall
 */

resource "google_compute_instance" "panos" {
    count = 1
    name = "panos"
    machine_type = "n1-standard-4"
    zone = "europe-west2-a"
    can_ip_forward = true
    allow_stopping_for_update = true
    metadata {
        serial-port-enable = true
        ssh-keys = "admin:${file("${var.gcp_ssh_key}")}"
        vmseries-bootstrap-gce-storagebucket = "auto-hack-cloud"
    }
    service_account {
        scopes = [
            "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring.write",
        ]
    }
    network_interface {
        subnetwork = "mgmt-net"
        address = "192.168.0.2"
        access_config {
            nat_ip = "${google_compute_address.mgmt-pip.address}"
        }
    }

    network_interface {
        subnetwork = "outside-net"
        address = "172.16.0.2"
        access_config {
            nat_ip = "${google_compute_address.outside-pip.address}"
        }
    }
  
    network_interface {
        address = "10.10.10.2"
        subnetwork = "inside-net"
    }

    boot_disk {
        initialize_params {
            image = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-byol-810"
        }
    }
    depends_on = ["google_compute_subnetwork.mgmt-net", "google_compute_subnetwork.inside-net", "google_compute_subnetwork.outside-net"]
}

/*
 *  Linux victim
 */

resource "google_compute_instance" "linux" {
  name         = "linux"
  machine_type = "n1-standard-1"
  zone         = "europe-west2-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1404-trusty-v20180818"
    }
  }

  network_interface {
    subnetwork = "inside-net"
    address = "10.10.10.101"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "wget https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/linuxserver-startup.sh \n chmod 755 linuxserver-startup.sh \n ./linuxserver-startup.sh"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = ["google_compute_subnetwork.inside-net"]
}

/*
 *  Kali attacker
 */

resource "google_compute_instance" "kali" {
  name         = "kali"
  machine_type = "n1-standard-1"
  zone         = "europe-west2-a"

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7-v20180815"
    }
  }

  network_interface {
    subnetwork = "outside-net"
    address = "172.16.0.10"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "wget https://raw.githubusercontent.com/jamesholland-uk/auto-hack-cloud/master/kali-startup.sh \n chmod 755 kali-startup.sh \n ./kali-startup.sh"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = ["google_compute_subnetwork.outside-net"]
}

/*
 *  GCP Routing
 */
 
resource "google_compute_route" "outside-route-to-ngfw" {
  name        = "outside-route-to-ngfw"
  dest_range  = "10.10.10.0/24"
  network     = "outside"
  next_hop_ip = "172.16.0.2"
  priority    = 100
  depends_on = ["google_compute_network.outside"]
}
 
resource "google_compute_route" "inside-route-to-ngfw" {
  name        = "inside-route-to-ngfw"
  dest_range  = "172.16.0.0/24"
  network     = "inside"
  next_hop_ip = "10.10.10.2"
  priority    = 100
  depends_on = ["google_compute_network.inside"]
}

 /*
 *  GCP Firewall Rules
 */

resource "google_compute_firewall" "internet-ingress-for-mgt" {
    name = "internet-ingress-for-mgt"
    network = "mgmt"
    allow {
        protocol = "tcp"
        ports = ["80", "443"]
    }
    source_ranges = ["81.107.157.88"]
    depends_on = ["google_compute_network.mgmt"]
}

resource "google_compute_firewall" "internet-ingress-for-outside" {
    name = "internet-ingress-for-outside"
    network = "outside"
    allow = [ 
        {
          protocol = "tcp"
          ports = ["22", "80", "443", "3389", "8080"]
        },
        {
          protocol = "udp"
          ports = ["4501"]
        }
    ]
    source_ranges = ["81.107.157.88"]
    depends_on = ["google_compute_network.outside"]
}

resource "google_compute_firewall" "internet-ingress-for-inside" {
    name = "internet-ingress-for-inside"
    network = "inside"
    allow {
        protocol = "tcp"
        ports = ["22", "80", "443", "3389", "8080"]
    }
    source_ranges = ["81.107.157.88"]
    depends_on = ["google_compute_network.inside"]
}

resource "google_compute_firewall" "inside-to-outside" {
    name = "outside-to-inside"
    network = "inside"
    allow {
        protocol = "all"
        // Any port
    }
    source_ranges = ["172.16.0.0/24"]
    depends_on = ["google_compute_network.inside"]
}

resource "google_compute_firewall" "outside-to-inside" {
    name = "inside-to-outside"
    network = "outside"
    allow {
        protocol = "all"
        // Any port
    }
    source_ranges = ["10.10.10.0/24"]
    depends_on = ["google_compute_network.outside"]
}