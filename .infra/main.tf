terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.62.1"
    }
  }
}


provider "google" {
  project = "andes-384517"
  region  = "us-east1"
}