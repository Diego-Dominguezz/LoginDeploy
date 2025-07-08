group "default" {
    targets = ["production"]
}

group "all" {
    targets = ["test", "production"]
}

target "test" {
  context = "."
  dockerfile = "Dockerfile"
  tags = [
    "diegodguez/proyectologin:test"
  ]
  args = {
    NODE_ENV = "test"
  }
}

target "production" {
  context = "."
  dockerfile = "Dockerfile"
  tags = [
    "diegodguez/proyectologin:latest"
  ]
  args = {
    NODE_ENV = "production"
  }
}
