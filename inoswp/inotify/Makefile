CC=gcc
# LUADIR=/home/rasmus/Downloads/lua/lua-5.4.3/src
LUADIR=/usr/include/lua5.4
TEST=inotify_swp
TARGET=~/bin/inoswp

.PHONY: ${TARGET}

test:
	$(CC) -std=c99 -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -g \
		-I../lib \
		-I$(LUADIR) \
		-pedantic -Wall -W -Wmissing-prototypes \
		-Wno-sign-compare -Wimplicit-fallthrough -Wno-unused-parameter \
		inotify_swp.c filter_file.c ../libtlpi.a -llua5.4 -lrt -o $(TEST)
inoswp:
	$(CC) -std=c99 -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -g \
		-I../lib \
		-I$(LUADIR) \
		-pedantic -Wall -W -Wmissing-prototypes \
		-Wno-sign-compare -Wimplicit-fallthrough -Wno-unused-parameter \
		inotify_swp.c filter_file.c ../libtlpi.a -llua5.4 -lrt -o $(TARGET)

clean:
	rm ~/bin/inoswp
