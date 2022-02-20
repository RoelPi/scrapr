resource "random_string" "random_suffix" {
  length           = 5
  special          = false
  override_special = "/@£$"
}
/*
resource "google_sql_database_instance" "gp_database" {
  name             = "gp-database-${random_string.random_suffix.result}"
*/

resource "random_pet" "pet" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    some_id = "100"
  }
  length = 10
}

output "random_pet" {
  value = random_pet.pet.id
}