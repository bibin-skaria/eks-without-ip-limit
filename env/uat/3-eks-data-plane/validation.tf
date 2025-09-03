# Validation checks for variable relationships and logic
locals {
  # Validate node group scaling configuration
  validate_scaling_config = {
    min_max_check = var.node_group_min_size <= var.node_group_max_size ? true : tobool("ERROR: node_group_min_size must be <= node_group_max_size")
    desired_range_check = (var.node_group_desired_size >= var.node_group_min_size && var.node_group_desired_size <= var.node_group_max_size) ? true : tobool("ERROR: node_group_desired_size must be between min_size and max_size")
  }
}