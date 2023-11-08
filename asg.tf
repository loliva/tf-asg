resource "aws_launch_template" "launch_template" {
  name = "Launch_template_mod4"
  description = "Launch Template modulo 4"
  image_id = aws_ami_from_instance.custom.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_ec2.id, aws_security_group.sg_private_ssh.id]
  update_default_version = true
  monitoring {
    enabled = true
  }
  iam_instance_profile {
    name = module.ssm_instance_profile.aws_iam_instance_profile
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "asg-mod4"
      Owner = "loliva"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix = "asg-"
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  vpc_zone_identifier  = [
    module.vpc.public_subnets[0],
    module.vpc.public_subnets[1]  
    ]
  target_group_arns = module.alb.target_group_arns
  health_check_type = "EC2"
  wait_for_capacity_timeout = 0
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      instance_warmup = 100
      min_healthy_percentage = 50      
    }
  }  
  tag {
    key                 = "Owners"
    value               = "loliva"
    propagate_at_launch = true
  }      
}

resource "aws_autoscaling_policy" "avg_cpu_policy_10" {
  name                   = "avg-cpu-policy-10"
  policy_type = "TargetTrackingScaling"  
  autoscaling_group_name = aws_autoscaling_group.asg.id 
  estimated_instance_warmup = 10
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 10
  }  
}
