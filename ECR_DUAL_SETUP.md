# Dual ECR Setup Guide

This project supports both private and public Amazon ECR repositories with automatic fallback for users without AWS credentials.

## Prerequisites

1. **Set up your public ECR alias**: Replace `your-alias` in all configuration files with your actual public ECR alias.
2. **AWS CLI configured** (for pushing images)
3. **Docker installed**

## Configuration Files Updated

- `docker-bake.hcl`: Now builds and tags images for both private and public ECR
- `scripts/build-and-push.ps1`: PowerShell script to push to both registries
- `scripts/smart-deploy.ps1`: Smart deployment with ECR fallback
- `docker-compose.public.yml`: Compose file optimized for public ECR usage

## How It Works

### For Developers (with AWS credentials)

1. **Build and push to both ECR repositories:**

   ```bash
   npm run build-push              # Push production to both ECR repos
   npm run build-push testing     # Push testing to both ECR repos
   ```

2. **Deploy with smart fallback:**
   ```bash
   npm run deploy:smart            # Deploy production with ECR fallback
   npm run deploy:smart testing   # Deploy testing with ECR fallback
   ```

### For Users (without AWS credentials)

Users without AWS credentials can still run the project by:

1. **Using the public ECR directly:**

   ```bash
   docker-compose -f docker-compose.public.yml up -d
   ```

2. **Using smart deployment (tries private first, falls back to public):**
   ```bash
   # Download smart-deploy.ps1 and run:
   .\smart-deploy.ps1
   ```

## ECR Fallback Logic

The smart deployment script follows this logic:

1. **Try Private ECR**: Attempts to authenticate and pull from private ECR
2. **Fallback to Public ECR**: If private fails, automatically switches to public ECR
3. **Error Handling**: Provides clear feedback about which registry is being used

## Environment Variables

The following environment variables can be set to customize behavior:

- `ECR_REGISTRY`: Private ECR registry URL (default: `488343657053.dkr.ecr.us-east-2.amazonaws.com`)
- `PUBLIC_ECR_REGISTRY`: Public ECR registry URL (default: `public.ecr.aws/your-alias`)
- `IMAGE_TAG`: Image tag to use (default: `latest` for production, `testing` for testing)
- `HOST_PORT`: Port to expose on host (default: `80` for production, `8080` for testing)

## Setting Up Public ECR

1. **Create a public repository in AWS ECR:**

   ```bash
   aws ecr-public create-repository --repository-name login-ejemplo --region us-east-1
   ```

2. **Get your public ECR alias:**

   ```bash
   aws ecr-public describe-registries --region us-east-1
   ```

3. **Update all configuration files** with your actual public ECR alias.

## Benefits

- **Developer Experience**: Developers with AWS access use private ECR (faster, more secure)
- **Public Access**: Users without AWS credentials can still run the project
- **Automatic Fallback**: No manual intervention needed - the system chooses the best option
- **Cost Optimization**: Public ECR has different pricing than private ECR

## Troubleshooting

### Common Issues

1. **"your-alias" not found**: You need to replace `your-alias` with your actual public ECR alias
2. **Authentication failed**: Make sure AWS CLI is configured for private ECR access
3. **Image not found**: Ensure images have been pushed to both repositories

### Debug Commands

```bash
# Test private ECR access
aws ecr describe-repositories --repository-names login-ejemplo

# Test public ECR access
aws ecr-public describe-repositories --repository-names login-ejemplo --region us-east-1

# List available images
docker images | grep login-ejemplo
```

## Security Considerations

- **Private ECR**: Use for sensitive or proprietary images
- **Public ECR**: Only use for images that can be publicly accessible
- **Environment Variables**: Keep sensitive configuration in private deployments only
