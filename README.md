# hackster-programmer

This is the repository for the Python programming script which is used to interact with the "Hackster" hardware security and hardware development platform. 

I also include the hackster-fw compiled uf2 image which runs on the RP2040 programmer (and is what this Python script interacts with), as well as the Dockerfile needed to build the development environment ecosystem on a user's PC.

## Instructions to build the Docker image (takes a while)

```bash
$ git clone https://github.com/kiwih/hackster-programmer.git hackster-programmer
$ cd hackster-programmer
$ docker build -t hackster-deps:v1 .
```

Better to use the pre-built image from Docker Hub (note: not published yet):

```bash
$ docker pull kiwih/hackster-deps:v1
```

## Instructions for use

(See the tutorial google doc, link to be provided later)