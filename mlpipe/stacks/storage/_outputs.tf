# This is where you put your outputs declaration

output "datasets_efs" {
  value = data.aws_efs_file_system.datasets
}
