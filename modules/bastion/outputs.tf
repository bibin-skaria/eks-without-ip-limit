output "launch_template_id" {
  description = "ID of the bastion launch template"
  value       = aws_launch_template.bastion.id
}

output "launch_template_arn" {
  description = "ARN of the bastion launch template"
  value       = aws_launch_template.bastion.arn
}

output "autoscaling_group_id" {
  description = "ID of the bastion autoscaling group"
  value       = aws_autoscaling_group.bastion.id
}

output "autoscaling_group_arn" {
  description = "ARN of the bastion autoscaling group"
  value       = aws_autoscaling_group.bastion.arn
}

output "iam_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = var.enable_ssm ? aws_iam_role.bastion[0].arn : null
}

output "iam_instance_profile_name" {
  description = "Name of the bastion IAM instance profile"
  value       = var.enable_ssm ? aws_iam_instance_profile.bastion[0].name : null
}