.POSIX:

CRYSTAL = crystal

test: .phony
	$(CRYSTAL) run test/*_test.cr -- --parallel 1

run:
	$(CRYSTAL) run src/secrets-cli.cr

build:
	shards build --production

.phony:
