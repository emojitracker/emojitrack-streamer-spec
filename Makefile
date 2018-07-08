.PHONY: container clobber

docker-tag := emojitracker/streamer-spec

container:
	docker build -t $(docker-tag) .

clobber:
	rm -rf node_modules
