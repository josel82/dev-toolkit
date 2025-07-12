variable "api_url" {}
variable "node" {}
variable "ci_user" {}
variable "sshkeys" {
    description = "A list of SSH public keys to add to instances."
    type        = list(string)
}
variable "node_count" {
    type        = number
    default     = 3
}