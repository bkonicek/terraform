variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
  default     = "ocid1.tenancy.oc1..aaaaaaaagrijaszt6hht7kcyfsjbgax6d4kigppo234qrs2f6ftp5k7nlocq"
}
variable "region" {
  type        = string
  description = "The region to provision the resources in"
  default     = "us-ashburn-1"
}

variable "base_url" {
  description = "The Okta base URL. Example: okta.com, oktapreview.com, etc. This is the domain part of your Okta org URL"
}
variable "org_name" {
  description = "The Okta org name. This is the part before the domain in your Okta org URL"
}
