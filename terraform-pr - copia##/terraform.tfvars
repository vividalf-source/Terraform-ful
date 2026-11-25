ambiente = "dev"

subredes = {
  pub_1  = { cidr = "10.0.1.0/24", az = "us-east-1a", publica = true }
  pub_2  = { cidr = "10.0.2.0/24", az = "us-east-1b", publica = true }
  priv_1 = { cidr = "10.0.3.0/24", az = "us-east-1a", publica = false }
  priv_2 = { cidr = "10.0.4.0/24", az = "us-east-1b", publica = false }
}

servidores = {
  biblioteca-a = { instance_type = "t3.medium", disk_size = 30, subred = "pub_1" }
  biblioteca-b = { instance_type = "t3.medium", disk_size = 30, subred = "pub_1" }
  biblioteca-c = { instance_type = "t3.large",  disk_size = 60, subred = "pub_2" }
}