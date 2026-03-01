DOCKERHUB_USER ?=
IMAGE := $(DOCKERHUB_USER)/healthy-http
VERSION := $(shell cat version.txt)

.PHONY: check-clean
check-clean:
	@test -z "$$(git status --porcelain)" || (echo "Error: uncommitted changes detected. Commit or stash them first."; exit 1)

.PHONY: build-version
build-version: check-clean
	@./scripts/incr-version build
	@$(MAKE) tag-and-push

.PHONY: patch-version
patch-version: check-clean
	@./scripts/incr-version patch
	@$(MAKE) tag-and-push

.PHONY: tag-and-push
tag-and-push:
	@V=$$(cat version.txt); git add version.txt && git commit -m "Release $$V" && git tag $$V && git push && git push origin $$V

VERSION_BUMP ?= build

.PHONY: docker
docker:
	@./scripts/incr-version $(VERSION_BUMP)
	@IMG=$(if $(DOCKERHUB_USER),$(DOCKERHUB_USER)/healthy-http,healthy-http); docker build -t $$IMG:$(shell cat version.txt) -t $$IMG:latest .

.PHONY: publish
publish:
	@test -n "$(DOCKERHUB_USER)" || (echo "Error: DOCKERHUB_USER is required. Usage: make DOCKERHUB_USER=youruser publish"; exit 1)
	@docker manifest inspect $(IMAGE):$(VERSION) >/dev/null 2>&1 && (echo "Error: $(VERSION) is already published to Docker Hub"; exit 1) || true
	@docker build -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .
	@docker push $(IMAGE):$(VERSION)
	@docker push $(IMAGE):latest
