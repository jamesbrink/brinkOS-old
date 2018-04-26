# brinkOS

Arch based distribution with influences from Apricity-OS



## Usage
The following commands all assume you have cloned this repo and it is your current working directory.

Build the brinkOS build container.

```shell
docker build -t brinkos .
```

build brinkOS

```shell
$ docker run -i -t --privileged -v `pwd`/iso:/iso --rm brinkos bash
```

