IMAGE_NAME=duorat

build-image:
	@echo "Building image: ${IMAGE_NAME}"
	docker build -f Dockerfile --tag ${IMAGE_NAME} .
