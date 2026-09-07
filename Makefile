SCHEMAS := schemas/common/address.schema.json schemas/purchasing/quote.schema.json
GOBIN := $(shell go env GOPATH)/bin

.PHONY: generate generate-go generate-ts generate-dart clean verify

generate: generate-go generate-ts generate-dart

# One invocation covering every schema that participates in a shared $ref, so a type like
# Address de-duplicates into a single declaration instead of Address/Address2 per target.
generate-go:
	$(GOBIN)/go-jsonschema \
		-p model \
		--struct-name-from-title \
		--tags json \
		--capitalization ID \
		-o generated/go/model/types.go \
		$(SCHEMAS)

generate-ts:
	npx quicktype \
		--src-lang schema \
		--lang typescript \
		--just-types \
		--no-date-times \
		$(foreach s,$(SCHEMAS),--src $(s)) \
		--out generated/ts/index.ts

generate-dart:
	npx quicktype \
		--src-lang schema \
		--lang dart \
		--no-date-times \
		$(foreach s,$(SCHEMAS),--src $(s)) \
		--out generated/dart/lib/src/models.dart

verify:
	cd generated/go && go build ./... && go vet ./... && go test ./... -cover
	npx tsc --noEmit -p generated/ts
	cd generated/dart && dart analyze

clean:
	rm -f generated/go/model/types.go generated/ts/index.ts generated/dart/lib/src/models.dart
