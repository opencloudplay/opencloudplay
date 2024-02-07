provider "google" {
  project = "observatory-383913"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_firewall" "parsec_firewall" {
  name    = "parsec-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"] # Default Parsec port, adjust if you use custom ports
  }

  source_ranges = ["0.0.0.0/0"] # Be as specific as possible with IP ranges for better security
  target_tags   = ["parsec-server"]
}

resource "google_compute_instance" "windows_gaming_server" {
  name         = "windows-gaming-server"
  machine_type = "n1-standard-2" # Adjust based on the gaming performance requirements
  zone         = "us-central1-a"
  tags         = ["game-server"]

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-server-2022-dc-v20240111"
    }
  }

  guest_accelerator {
    type  = "nvidia-tesla-p4"
    count = 1
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    windows-startup-script-ps1 = <<-EOF
      # PowerShell commands to enable Windows Audio Service
      Set-Service -Name Audiosrv -StartupType Automatic
      Start-Service -Name Audiosrv

      # Add additional commands here for installing Chrome, Steam, or configuring the system
      # Consider using a configuration management tool or GCP's startup scripts for complex setups
    EOF
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = true # Set to true to automatically restart the VM after it's terminated due to maintenance
    preemptible         = false
  }
  
}
