variable "ECR_REGISTRY" {
    default = "488343657053.dkr.ecr.us-east-2.amazonaws.com"
}

group "default" {
    targets = ["production"]
}

group "all" {
    targets = ["test", "testing", "production"]
}

group "testing-deploy" {
    targets = ["testing"]
}

target "test" {
    context = "."
    dockerfile = "Dockerfile"
    tags = [
    "${ECR_REGISTRY}/login-ejemplo:test"
  ]
    args = {
        NODE_ENV = "test"
    }
}

target "testing" {
    context = "."
    dockerfile = "Dockerfile"
    tags = [
    "${ECR_REGISTRY}/login-ejemplo:testing"
  ]
    args = {
        NODE_ENV = "testing"
    }
}

target "production" {
    context = "."
    dockerfile = "Dockerfile"
    tags = [
    "${ECR_REGISTRY}/login-ejemplo:latest"
  ]
    args = {
        NODE_ENV = "production"
    }
}
