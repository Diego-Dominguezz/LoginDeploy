group "default" {
  targets = ["app"]
}

target "app" {
  dockerfile = "Dockerfile"
  tags = ["login-app:latest"]
  args = {
    TARGETOS = "linux"
  }
}