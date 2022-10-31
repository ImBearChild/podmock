# Podmock

基于 Fedora 构建的 mock 容器镜像，专为 rootless 容器打造，自带 qemu-user 实现跨架构编译。

## 用法

创建一些用来存放 mock 相关文件的文件夹。

```terminal
mkdir -p ~/mock/{etc,var,root,cache}
MOCK_DIR=$HOME/mock
```

然后你可以直接运行容器内的 mock ，容器的 entrypoint 脚本会自动将参数传递给 mock。

```terminal
podman run --rm --privileged --tty --interactive --init \
             -v $MOCK_DIR/etc:/etc/mock:z \
             -v $MOCK_DIR/var:/var/lib/mock:z \
             -v $MOCK_DIR/root:/root:z \
             -v $MOCK_DIR/cache:/var/cache/mock:z \
             -v /:/media/root \
             -v $(pwd):/media/workdir \
             imbearchild/podmock \
             mock
```

你可以看到，我们给了 podman 许多参数。
`--privileged` 参数是在容器内运行 mock 所必须的参数，意味着容器内的最高权限与当前用户相同。
`--tty`, `--interactive`, `--init` 与 `--rm` 并非必须，可根据需要自行增减参数。
现在，我们可以做一些简化，设置一个 alias 会方便许多：

```
alias podmock="podman run --rm --privileged --tty --interactive --init \
             -v $MOCK_DIR/etc:/etc/mock:z \
             -v $MOCK_DIR/var:/var/lib/mock:z \
             -v $MOCK_DIR/root:/root:z \
             -v $MOCK_DIR/cache:/var/cache/mock:z \
             -v /:/media/root \
             -v $(pwd):/media/workdir \
             imbearchild/podmock"
```

你也可以直接在容器内启动交互式终端：

```
podmock bash
[root@ddebb89788cc /]#
```

同样，容器的 entrypoint 脚本会自动将参数传递给 bash。
注意，如果你需要使用标准输入和输出，请移除传递给 podman 的 `--tty` 选项。

### tun2socks

Podmock 内置了 tun2socks 代理支持。比如：

```
podman run --rm --privileged --tty -i \
       --env=socks_proxy=socks://127.0.0.1:9050 \
       --network=slirp4netns:allow_host_loopback=true \
       -v $MOCK_DIR/etc:/etc/mock:z \
       -v $MOCK_DIR/var:/var/lib/mock:z \
       -v $MOCK_DIR/root:/root:z \
       -v $MOCK_DIR/cache:/var/cache/mock:z \
       -v /tmp/compressed/mock:/tmp:z \
       -v /:/media/root \
       -v $(pwd):/media/workdir \
       imbearchild/podmock bash
```

此处的 127.0.0.1 会在容器内被替换为 10.0.2.2。

### binfmt_misc

为了实现跨架构编译， Podmock 也内置了 qemu-user。设置起来也很简单：

```
podman save imbearchild/podmock:latest | sudo podman load
sudo podman run --rm --privileged imbearchild/podmock:latest binfmt
```

这样，容器内外均可跨架构执行二进制。之后使用 podman 不再需要用 root 权限进行设置，
直接以普通用户权限执行即可。
