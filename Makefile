.PHONY: docs test

deps/mini.doc:
	mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.doc deps/mini.doc

docs: deps/mini.doc
	nvim --headless --noplugin -u NONE \
		-c "set rtp+=deps/mini.doc" \
		-c "luafile scripts/minidoc.lua" \
		-c "qa!"

test:
	nvim --headless -l tests/run.lua
