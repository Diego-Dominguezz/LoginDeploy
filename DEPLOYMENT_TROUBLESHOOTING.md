# AWS ECR + EC2 Deployment Troubleshooting Guide

## Required GitHub Secrets

Set these in your GitHub repository settings (Settings > Secrets and variables > Actions):

### AWS Configuration

```
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=us-east-1  # or your preferred region
```

### EC2 Configuration

```
EC2_HOST=your-production-server-ip
EC2_TESTING_HOST=your-testing-server-ip  # if using separate testing server
EC2_SSH_KEY=your_private_ssh_key_content
```

## AWS Setup

### 1. Create ECR Repository

```bash
aws ecr create-repository --repository-name login-ejemplo --region us-east-1
```

### 2. Create IAM User with ECR Permissions

Create an IAM user with these policies:

- `AmazonEC2ContainerRegistryFullAccess`
- Or custom policy:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ecr:GetAuthorizationToken",
				"ecr:BatchCheckLayerAvailability",
				"ecr:GetDownloadUrlForLayer",
				"ecr:BatchGetImage",
				"ecr:InitiateLayerUpload",
				"ecr:UploadLayerPart",
				"ecr:CompleteLayerUpload",
				"ecr:PutImage"
			],
			"Resource": "*"
		}
	]
}
```

## EC2 Setup

### 1. Launch Ubuntu 20.04+ Instance

- Security Group: Allow SSH (22), HTTP (80), and custom port 8080 for testing
- Key pair: Use the same key for both production and testing instances

### 2. Initial Server Setup (run once on each EC2 instance)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Create user if needed (optional, workflows use ubuntu user)
# The workflows will auto-install Docker and AWS CLI

# Ensure ubuntu user has sudo privileges
sudo usermod -aG sudo ubuntu

# Create deployment directory
mkdir -p ~/LoginDeploy
mkdir -p ~/LoginDeploy-Testing  # for testing server
```

## Common Issues and Solutions

### 1. "AWS credentials not found"

**Solution**: Ensure AWS secrets are set correctly in GitHub:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### 2. "Docker permission denied"

**Solution**: The workflow now handles this automatically by:

- Adding user to docker group
- Using sudo for docker commands
- Restarting docker service

### 3. "ECR login failed"

**Solution**: Check that:

- ECR repository exists: `login-ejemplo`
- IAM user has ECR permissions
- AWS region is correct

### 4. "SSH connection failed"

**Solution**: Verify:

- EC2 instance is running
- Security group allows SSH on port 22
- SSH key is correct and in OpenSSH format

### 5. "Port already in use"

**Solution**: Stop existing containers:

```bash
# On production server
cd ~/LoginDeploy
sudo docker compose down

# On testing server
cd ~/LoginDeploy-Testing
sudo docker compose -f docker-compose.testing.yml down
```

## Testing the Deployment

### 1. Check if services are running

```bash
# Production (port 80)
curl http://your-production-ip

# Testing (port 8080)
curl http://your-testing-ip:8080
```

### 2. View container logs

```bash
# Production
cd ~/LoginDeploy
sudo docker compose logs -f

# Testing
cd ~/LoginDeploy-Testing
sudo docker compose -f docker-compose.testing.yml logs -f
```

### 3. Check container status

```bash
# Production
sudo docker compose ps

# Testing
sudo docker compose -f docker-compose.testing.yml ps
```

## Workflow Triggers

- **Production Deploy**: Push to `main` branch
- **Testing Deploy**: Push to `develop` or `testing` branch

## Manual Deployment (Emergency)

If workflows fail, you can deploy manually:

```bash
# SSH to your server
ssh -i your-key.pem ubuntu@your-server-ip

# Navigate to deployment directory
cd ~/LoginDeploy

# Login to ECR manually
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin your-account-id.dkr.ecr.us-east-1.amazonaws.com

# Pull and start services
sudo docker compose pull
sudo docker compose up -d --remove-orphans
```

## Monitoring

### Check GitHub Actions

1. Go to your repo > Actions tab
2. Click on failed workflow to see logs
3. Look for specific error messages

### Check AWS ECR

```bash
# List images in repository
aws ecr describe-images --repository-name login-ejemplo --region us-east-1
```

### Check EC2 Resources

```bash
# Check disk space
df -h

# Check memory
free -h

# Check running processes
ps aux | grep docker
```
