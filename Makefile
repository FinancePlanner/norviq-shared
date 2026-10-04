.PHONY: help tag push-tag release lint

REMOTE ?= origin

help:
	@echo "Usage:"
	@echo "  make tag VERSION=v1.0.0"
	@echo "  make push-tag VERSION=v1.0.0"
	@echo "  make release VERSION=v1.0.0"
	@echo "  make lint"

tag:
	@test -n "$(VERSION)" || (echo "VERSION is required, e.g. make tag VERSION=v1.0.0" && exit 1)
	git tag $(VERSION)

push-tag:
	@test -n "$(VERSION)" || (echo "VERSION is required, e.g. make push-tag VERSION=v1.0.0" && exit 1)
	git push $(REMOTE) $(VERSION)

release: tag push-tag

lint:
	swiftformat . --lint
	swiftlint
	periphery scan
