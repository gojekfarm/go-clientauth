.PHONY: all
all: build-deps build fmt vet lint test

GO_LIST=$(shell go list)

setup:
	mkdir -p $(GOPATH)/bin
	go get -u github.com/golang/lint/golint
	go get -u -d github.com/mattes/migrate/cli
	go build -tags 'postgres' -o /usr/local/bin/migrate github.com/mattes/migrate/cli

build-deps:
	dep ensure

update-deps:
	dep ensure --update

compile:
	mkdir -p out/
	go build -race $(GO_LIST)

build: build-deps compile fmt vet lint

fmt:
	go fmt $(GO_LIST)

vet:
	go vet $(GO_LIST)

lint:
	@for p in $(UNIT_TEST_PACKAGES); do \
		echo "==> Linting $$p"; \
		golint -set_exit_status $$p; \
	done

db.create:
	createdb -Opostgres -Eutf8 client_auth

db.drop:
	dropdb --if-exists client_auth

db.migrate: db.drop db.create
	migrate -database "postgres://localhost:5432/client_auth?sslmode=disable" -path ./migrations up

test: db.migrate
	ENVIRONMENT=test go test -v -race $(GO_LIST)
