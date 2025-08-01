//List of OU names I want to create
variable "organizational_units" {
    description  = "Names of Organizational Units to provision"
    type = list(string)
    default = ["SecurityTeam", "DevOpsTeam"]
}


variable "scp_policies" {
    description = "Service control policies to attach"
    type = map(string)
    default = {
        BlockGlobalServices = "arn:aws:organizations::123456789012:policy/o-abcdef1234/BlockGlobalServices"
    }
}