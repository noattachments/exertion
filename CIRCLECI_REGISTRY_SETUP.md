# CircleCI Registry Setup Guide

This guide explains how to configure Docker registry settings in CircleCI to fix the `make build-push` command failures.

## The Problem

The `make build-push REGISTRY=${CIRCLE_PROJECT_USERNAME}` command was failing because:

1. `CIRCLE_PROJECT_USERNAME` is just the username, not a full registry URL
2. The registry variable wasn't properly set in the environment
3. No fallback was provided for different registry types

## The Solution

The CircleCI configuration has been updated to:

1. **Use environment variables properly**: Set `REGISTRY` variable in the environment
2. **Support multiple registry types**: Docker Hub, AWS ECR, Google GCR, etc.
3. **Provide fallbacks**: Default to a placeholder if no registry is configured

## How the REGISTRY Variable Works

The `build-and-push.sh` script uses the `REGISTRY` variable to create fully qualified Docker image names:

```bash
# The script creates images like:
$REGISTRY/exertion-app:$VERSION
$REGISTRY/exertion-app:$GIT_COMMIT
$REGISTRY/exertion-app:latest
$REGISTRY/exertion-nginx:$VERSION
$REGISTRY/exertion-nginx:$GIT_COMMIT
$REGISTRY/exertion-nginx:latest
```

### Valid REGISTRY Values

The `REGISTRY` variable should contain **only the registry hostname/username** (no trailing slash, no image name):

#### Docker Hub
```bash
REGISTRY="myusername"
# Results in: myusername/exertion-app:latest
```

#### AWS ECR (Elastic Container Registry)
```bash
REGISTRY="123456789012.dkr.ecr.us-west-2.amazonaws.com"
# Results in: 123456789012.dkr.ecr.us-west-2.amazonaws.com/exertion-app:latest
```

#### Google Container Registry (GCR)
```bash
REGISTRY="gcr.io/my-project-id"
# Results in: gcr.io/my-project-id/exertion-app:latest
```

#### Azure Container Registry (ACR)
```bash
REGISTRY="myregistry.azurecr.io"
# Results in: myregistry.azurecr.io/exertion-app:latest
```

#### GitHub Container Registry (GHCR)
```bash
REGISTRY="ghcr.io/myusername"
# Results in: ghcr.io/myusername/exertion-app:latest
```

#### Private Registry
```bash
REGISTRY="registry.mycompany.com:5000"
# Results in: registry.mycompany.com:5000/exertion-app:latest
```

### Common Mistakes to Avoid

❌ **Wrong**:
```bash
REGISTRY="myusername/"           # Trailing slash
REGISTRY="myusername/exertion"   # Includes image name
REGISTRY="https://myusername"    # Includes protocol
```

✅ **Correct**:
```bash
REGISTRY="myusername"            # Just the registry/username
REGISTRY="gcr.io/my-project"     # Full registry hostname
```

## Configuration Options

### Option 1: Docker Hub (Default)

For Docker Hub, CircleCI will automatically use `CIRCLE_PROJECT_USERNAME` as the registry:

```yaml
# No additional configuration needed
# CircleCI will use: ${CIRCLE_PROJECT_USERNAME}/exertion-app:version
```

### Option 2: Custom Registry

Set the `DOCKER_REGISTRY` environment variable in CircleCI project settings:

```bash
# For AWS ECR
DOCKER_REGISTRY=123456789012.dkr.ecr.us-west-2.amazonaws.com

# For Google GCR
DOCKER_REGISTRY=gcr.io/your-project-id

# For Azure ACR
DOCKER_REGISTRY=your-registry.azurecr.io

# For GitHub GHCR
DOCKER_REGISTRY=ghcr.io/your-username

# For custom registry
DOCKER_REGISTRY=registry.yourcompany.com
```

### Option 3: Environment-Specific Registry

You can also set different registries for different environments:

```bash
# In CircleCI project settings
DOCKER_REGISTRY_STAGING=staging-registry.com
DOCKER_REGISTRY_PRODUCTION=prod-registry.com
```

## Required Environment Variables

### For CircleCI

Make sure these are set in your CircleCI project settings:

#### Required
- `DOCKER_USERNAME`: Your Docker registry username
- `DOCKER_PASSWORD`: Your Docker registry password/token

#### Optional
- `DOCKER_REGISTRY`: Custom registry URL (if not using Docker Hub)

### For Local Development

Add `REGISTRY_SRC` to your `.env` file for local development:

```bash
# In .env file
REGISTRY_SRC=myusername
```

This allows you to run `./build-and-push.sh` without arguments and it will automatically use your configured registry.

## Registry-Specific Setup

### Docker Hub

1. Go to CircleCI project settings
2. Add environment variables:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub password or access token

### AWS ECR

1. Create an ECR repository
2. Set up IAM permissions for CircleCI
3. Add environment variables:
   - `DOCKER_USERNAME`: AWS Access Key ID
   - `DOCKER_PASSWORD`: AWS Secret Access Key
   - `DOCKER_REGISTRY`: `123456789012.dkr.ecr.us-west-2.amazonaws.com`

### Google GCR

1. Enable Container Registry API
2. Create a service account with Storage Admin role
3. Add environment variables:
   - `DOCKER_USERNAME`: `_json_key`
   - `DOCKER_PASSWORD`: Service account JSON key
   - `DOCKER_REGISTRY`: `gcr.io/your-project-id`

## Testing the Fix

### Local Testing

You can test the registry configuration locally using the `build-and-push.sh` script. The script now supports multiple ways to specify the registry:

#### Method 1: Using .env File (Recommended)

Add `REGISTRY_SRC` to your `.env` file:
```bash
# In .env file
REGISTRY_SRC=myusername
```

Then run the script without arguments:
```bash
# Uses REGISTRY_SRC from .env file
./build-and-push.sh

# Uses REGISTRY_SRC from .env file with specific version
./build-and-push.sh "" v1.0.0
```

#### Method 2: Command Line Arguments

```bash
# Test with Docker Hub (replace 'myusername' with your actual username)
./build-and-push.sh myusername v1.0.0

# Test with AWS ECR
./build-and-push.sh 123456789012.dkr.ecr.us-west-2.amazonaws.com v1.0.0

# Test with Google GCR
./build-and-push.sh gcr.io/my-project-id v1.0.0

# Test with Azure ACR
./build-and-push.sh myregistry.azurecr.io v1.0.0

# Test with GitHub GHCR
./build-and-push.sh ghcr.io/myusername v1.0.0
```

#### Method 3: Environment Variables

```bash
# Set environment variable
export REGISTRY="myusername"
./build-and-push.sh

# Or inline
REGISTRY="myusername" ./build-and-push.sh
```

### Registry Priority Order

The script follows this priority order (highest to lowest):

1. **Command line argument**: `./build-and-push.sh myregistry.com`
2. **REGISTRY_SRC in .env file**: `REGISTRY_SRC=myregistry.com`
3. **Default fallback**: `your-registry.com`

### Using Make Commands

```bash
# Test with default registry (will show warning)
make build-push

# Test with custom registry
make build-push REGISTRY=myusername

# Test with version
make build-push REGISTRY=myusername v1.0.0
```

### Environment Variable Testing

```bash
# Set environment variable
export REGISTRY="myusername"
make build-push

# Or inline
REGISTRY="myusername" make build-push
```

### What the Script Does

The `build-and-push.sh` script performs these steps:

1. **Builds Docker images** using `docker-compose -f docker-compose.local.yml build`
2. **Tags images** with multiple tags for each registry:
   - `$REGISTRY/exertion-app:$VERSION`
   - `$REGISTRY/exertion-app:$GIT_COMMIT`
   - `$REGISTRY/exertion-app:latest`
   - `$REGISTRY/exertion-nginx:$VERSION`
   - `$REGISTRY/exertion-nginx:$GIT_COMMIT`
   - `$REGISTRY/exertion-nginx:latest`
3. **Pushes images** to the specified registry

### CircleCI Testing

1. Push your changes to trigger CircleCI
2. Check the build logs for:
   - ✅ "Registry: your-registry-name"
   - ✅ "Building and pushing Docker images..."
   - ✅ "Successfully built and pushed images!"

## Troubleshooting

### Error: "Registry not found"
- Check that `DOCKER_REGISTRY` is set correctly
- Verify the registry URL format

### Error: "Authentication failed"
- Check `DOCKER_USERNAME` and `DOCKER_PASSWORD`
- Verify credentials have push permissions

### Error: "Image not found"
- Check that the registry URL includes the correct path
- Verify the image name format

## Example CircleCI Environment Variables

```bash
# For Docker Hub
DOCKER_USERNAME=myusername
DOCKER_PASSWORD=mypassword

# For AWS ECR
DOCKER_USERNAME=AKIAIOSFODNN7EXAMPLE
DOCKER_PASSWORD=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
DOCKER_REGISTRY=123456789012.dkr.ecr.us-west-2.amazonaws.com

# For Google GCR
DOCKER_USERNAME=_json_key
DOCKER_PASSWORD={"type":"service_account","project_id":"..."}
DOCKER_REGISTRY=gcr.io/my-project-id

# For GitHub GHCR
DOCKER_USERNAME=myusername
DOCKER_PASSWORD=ghp_xxxxxxxxxxxxxxxxxxxx
DOCKER_REGISTRY=ghcr.io/myusername

# For Azure ACR
DOCKER_USERNAME=myregistry
DOCKER_PASSWORD=xxxxxxxxxxxxxxxxxxxx
DOCKER_REGISTRY=myregistry.azurecr.io
```

## Security Notes

- Use access tokens instead of passwords when possible
- Rotate credentials regularly
- Use least-privilege permissions
- Consider using CircleCI contexts for shared secrets

## Next Steps

1. Set up your registry credentials in CircleCI
2. Push your changes to trigger a build
3. Verify the build-push step completes successfully
4. Check that images are pushed to your registry
