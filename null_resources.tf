# Start the Config Recorder after everything is set up
resource "null_resource" "start_config_recorder" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "aws configservice start-configuration-recorder --configuration-recorder-name ${aws_config_configuration_recorder.recorder.name}"
    interpreter = ["bash", "-c"]
  }

  depends_on = [
    aws_config_delivery_channel.delivery_channel,
    aws_config_configuration_recorder.recorder,
    aws_config_config_rule.s3_bucket_public_read_prohibited,
    aws_config_config_rule.s3_bucket_encrypted,
    aws_config_config_rule.root_account_mfa_enabled,
    aws_config_config_rule.ec2_instance_no_public_ip
  ]
}
