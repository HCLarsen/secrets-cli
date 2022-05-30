.POSIX:

CRYSTAL = crystal

test: .phony
	$(CRYSTAL) run test/*_test.cr -- --parallel 1

run:
	$(CRYSTAL) run src/run.cr

build:
	shards build --no-debug --release --production

.phony:
