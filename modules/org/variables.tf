//List of OU names I want to create
variable "organizational_units" {
  description = "Names of Organizational Units to provision"
  type        = list(string)
  default     = ["SecurityTeam", "DevOpsTeam"]
}


variable "scp_policies" {
  description = "Service control policies to attach"
  type        = map(string)
  default = {
    DevOpsTeam   = "p-57oic78t",
    SecurityTeam = "p-57oic78t"
  }
}