# Sci-fi Ball 科幻足球源码

## Build
```
$ moon version --all
moon 0.1.20241111 (e6d64e0 2024-11-11) ~/.moon/bin/moon
moonc v0.1.20241111+dc2407357 ~/.moon/bin/moonc
moonrun 0.1.20241111 (e6d64e0 2024-11-11) ~/.moon/bin/moonrun
```

Make sure you have correct MoonBit version.

```
$ moon build --target wasm
```

## Verify

```
$ sha512sum target/wasm/release/build/game.wasm
4a394591768af88195b37187df0276251d882da9fe5b02d01eb993ef611d953bfbf86187a92a08c34e45e8632b9b906dce8d7242c3664fad3b1da3c6e16d84e2  target/wasm/release/build/game.wasm
```

## License

Apache-2.0
