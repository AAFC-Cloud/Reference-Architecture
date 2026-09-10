variable "source_root" {
  description = "Git checkout containing AzureDevOps/Projects/<project>/Repos/<repository>. Defaults to this root's parent directory."
  type        = string
  default     = null
}
