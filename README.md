# Podmock

[\[中文/Chinese\]](./README.zh_cn.md)

A mock container image built on Fedora.

## Pull

You can pull from Docker.io:

```terminal
podman pull docker.io/imbearchild/podmock
```

## Run

Create the directories to be used for the mock config files and mock build directory.

```terminal
mkdir -p ~/mock/{etc,var,root,cache}
```

You can then run the container, since the `mock` command is the entrypoint you can pass any options relavent to `mock`.

```terminal
podman run --rm --privileged --tty -i \
             -v $MOCK_DIR/etc:/etc/mock:z \
             -v $MOCK_DIR/var:/var/lib/mock:z \
             -v $MOCK_DIR/root:/root:z \
             -v $MOCK_DIR/cache:/var/cache/mock:z \
             -v /:/media/root \
             -v $(pwd):/media/workdir \
             imbearchild/podmock \
             mock
```
