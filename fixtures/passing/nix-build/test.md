```console example=b
$ nix-build '<nixpkgs>' -A hello
/nix/store/...-hello-...
$ ./result/bin/hello
Hello, world!
```
