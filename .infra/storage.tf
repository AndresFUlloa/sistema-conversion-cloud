resource "google_storage_bucket" "files" {
  name          = "compressor-files-store"
  location      = "US"
  force_destroy = true
}