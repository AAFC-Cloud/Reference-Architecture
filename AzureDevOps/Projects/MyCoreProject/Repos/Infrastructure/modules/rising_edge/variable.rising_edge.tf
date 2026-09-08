variable "rising_edge" {
  type        = bool
  description = "Whether the caller currently requires reconciliation. A true value advances the generation once per apply attempt."
}
