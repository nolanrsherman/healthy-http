# healthy-http

A minimal, public Docker image that Terraform users can deploy as a placeholder service for Cloud Run, Elastic Beanstalk, and similar platforms. It runs a simple HTTP server that returns healthy status, allowing deployments to succeed when you need a valid image before your real application is ready.

## The Problem

When provisioning infrastructure with Terraform, a common deployment order is:

1. Create a container registry (AWS ECR, GCP Artifact Registry, etc.)
2. Deploy a service that pulls an image from that registry (Cloud Run, Elastic Beanstalk, ECS, etc.)

Platforms like **Cloud Run** and **Elastic Beanstalk** require a container image that passes health checks before the deployment is considered successful. If you deploy a service that references an image that doesn't exist yet, or one that fails health checks, the deployment will fail—even if your registry and infrastructure are correctly configured.

## The Solution

`healthy-http` provides a tiny, ready-to-use Docker image that:

- Responds with `200 OK` on health-check endpoints
- Starts quickly and reliably
- Can be used immediately without pushing your own image

Use it as an initial image when creating services that depend on a registry, then swap to your real application image once it's built and pushed.

### Prerequisites

- Docker installed locally

### Steps

```bash
docker pull nolanrsherman/healthy-http:latest
```

## Usage

### Docker

```bash
docker run -p 8080:8080 nolanrsherman/healthy-http:latest
```

Override the port with the `PORT` environment variable:

```bash
docker run -e PORT=3000 -p 3000:3000 nolanrsherman/healthy-http:latest
```

### Terraform (Cloud Run example)

```hcl
resource "google_cloud_run_v2_service" "placeholder" {
  name     = "my-service"
  location = "us-central1"

  template {
    containers {
      image = "YOUR_DOCKERHUB_USERNAME/healthy-http:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
      }

      liveness_probe {
        http_get {
          path = "/health"
        }
      }
    }
  }
}
```

### Terraform (Elastic Beanstalk example)

```hcl
resource "aws_elastic_beanstalk_application_version" "placeholder" {
  name        = "placeholder-v1"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.eb_bucket.id
  key         = aws_s3_object.eb_object.id
  source = {
    repository = "YOUR_DOCKERHUB_USERNAME/healthy-http"
    tag        = "latest"
  }
}
```

## Health Check Endpoints

The service exposes these endpoints, each returning `200 OK` and `{"status":"ok"}`:

- `GET /` — Root
- `GET /health` — Standard health check (Cloud Run, many frameworks)
- `GET /healthy` — Alternate convention
- `GET /healthz` — Kubernetes-style health check

## License

See [LICENSE](LICENSE) for details.


## How to Publish

### Prerequisites

- A [Docker Hub](https://hub.docker.com/) account
- Docker installed locally

### Steps

1. **Log in to Docker Hub**

   ```bash
   docker login
   ```

2. **Build and publish** using the Makefile (fails if the version is already published):

   ```bash
   make DOCKERHUB_USER=your-username publish
   ```

   This builds the image tagged with the current version in `version.txt`, pushes it to Docker Hub, and also updates the `latest` tag.

3. **Make the repository public** (optional)

   In Docker Hub: go to your repository → Settings → Make Public.

### Version management

- `make build-version` — Increment build version (e.g. v1.0.0 → v1.0.0.1), create and push git tag. Fails if there are uncommitted changes.
- `make patch-version` — Increment patch version (e.g. v1.0.0 → v1.0.1), create and push git tag. Fails if there are uncommitted changes.
- `make docker` — Increment build version and build the image locally (no push).
