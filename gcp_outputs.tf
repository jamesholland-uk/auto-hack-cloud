/*
 * Copyright 2017 Google Inc.
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
 * Terraform output variables for GCP.
 */

output "PAN-OS IP" {
    value = "${google_compute_instance.panos.network_interface.0.access_config.0.nat_ip}"
}

output "Kali IP" {
    value = "${google_compute_instance.kali.network_interface.0.access_config.0.nat_ip}"
}

output "Linux IP" {
    value = "${google_compute_instance.linux.network_interface.0.access_config.0.nat_ip}"
}

output "GCP Zone" {
    value = "${google_compute_instance.panos.zone}"
}

output "Project" {
    value = "${var.gcp_project_id}"
}
