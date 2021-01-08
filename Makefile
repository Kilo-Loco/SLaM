install:
	swift build -c release
	install .build/release/slam /usr/local/bin/slam
