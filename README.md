# kytos-docker

[Kytos-NG SDN Platform](https://github.com/kytos-ng/) in a docker container with the main Napps used by [AmLight/AMPATH](https://www.amlight.net).

**NOTE: Since Kytos project is in a "shutdown" phase, our docker image is based on the fork of the project - Kytos-NG (https://github.com/kytos-ng). The naming convention inside the docker image remains the same, but eventually they will be changed to kytos-ng in the future.**

## Build

You can build the docker image by just running:

       docker build -f Dockerfile --no-cache -t amlight/kytos .

You can also use some build arguments to specify which branch should be used on each component (core and Napps):

       docker build -f Dockerfile --build-arg branch_mef_eline=fix/issue_xpto --build-arg branch_kytos_utils=fix/error_foobar -t amlight/kytos .

The UI components/files are built along with Kytos components and you can also specify the specific branch to use (defaults to master):

       docker build -f Dockerfile --build-arg branch_ui=release/2025.1.2 -t amlight/kytos .

While building the UI components/files, we overwrite the "version" to display the commit ID used on the build, you can disable this behavior by using `--build-arg ui_commit_version_tag=no` (which will maintain the version as defined on the UI's `package.json` file).

When running in a CI/CD with environment variables:

       env | grep ^branch_ | sed -e 's/^/--build-arg /' | xargs docker build -f Dockerfile --no-cache -t amlight/kytos .

## Usage

**OBS:** please check the notes below related to Kytos-ng dependencies.

After pull or build the image, you can run:

	docker run -d --name kytos -p 8181:8181 -p 6653:6653 amlight/kytos:latest

You can also run the kytos daemon as the main container process (the default is to run a `tail -f /dev/null` as the main process and kytos runs as an additional process):

	docker run -d --name kytos -p 8181:8181 -p 6653:6653 -it amlight/kytos:latest /usr/local/bin/kytosd -E -f

The Kytos docker image includes Mininet emulation platform by default. Thus, if you want to run a test topology you can run the following:
```
docker run -d --name kytos -v /lib/modules:/lib/modules --privileged amlight/kytos:latest
docker exec kytos tmux new-session -d -s mn mn --controller=remote --topo=linear,3
```

Help:
```
prompt$ docker run --rm amlight/kytos:latest --help
docker run amlight/kytos [options]
    -h, --help                    display help information
    /path/program ARG1 .. ARGn    execute the specfified local program
    --ARG1 .. --ARGn              execute Kytos with these arguments
```

> [!IMPORTANT]
> Kytos-ng dependencies

The Kytos-ng docker image depends on some additional software like MongoDB, Elastic Search, Kafka, etc. The very minimal dependency is MongoDB, which guarantee data persistency. We recommend you to use the official docker compose ([here](https://github.com/kytos-ng/kytos/blob/master/docker-compose.yml) and [here](https://github.com/kytos-ng/kytos/blob/master/docker-compose.es.yml)), which includes all those dependencies. An alternative would be running a single container for MongoDB and then link it into Kytos:

```
docker run -d --name mongo1 mongo:7.0
docker exec -it mongo1 mongosh --eval 'db.getSiblingDB("k1").createUser({user: "k1", pwd: "k1", roles: [ { role: "dbAdmin", db: "k1" } ]})'
docker run -d --name kytos1 --link mongo1 -e MONGO_DBNAME=k1 -e MONGO_USERNAME=k1 -e MONGO_PASSWORD=k1 -e MONGO_HOST_SEEDS=mongo1:27017 amlight/kytos:latest
```
