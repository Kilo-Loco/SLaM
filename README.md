# Swift Lambda Maker

Swift Lambda Maker, aka SLaM, is a CLI tooled used for creating and packaging AWS Lambda function written in Swift. It can create a new executable Swift Package where you can start coding your Lambda as well as package that Lambda as a zipped Docker image.

## Prerequisites
- [Swift 5.3+](https://swift.org/download/#releases)
- [Docker](https://www.docker.com/get-started)

## Getting Started

To download and install SLaM, run the following commands in the terminal:

```bash
$ git clone https://github.com/Kilo-Loco/SLaM.git
$ cd SLaM
$ make
```

Next, generate the Swift Lambda project in a new directory (outside of the SLaM directory):

```bash
$ mkdir MyFirstLambda
$ cd MyFirstLambda
$ slam new
```

Open your project and start coding your Lambda 🚀

```bash
$ xed .
```

## Exporting

To deploy your Swift Lambda, you will need to first create a Docker image:

```bash
$ slam setup-image

Enter the name of your image:
my-first-lambda-image
```

> Once a Docker image is created, you shouldn't have to run this command again

Now build and package your code into the Docker image:

```bash
$ slam export

Enter the name of your image:
my-first-lambda-image
```

> Run this command every time you need to package your updated Swift Lambda.

Once the export if finished, you can find the zipped Docker image at `pathToThisRepo/.build/lambda/[PROJECT_NAME]/lambda.zip`


## Contributions and Support

SLaM is developed completely in the open, and contributions are welcomed. [Kilo Loco](https://github.com/kilo-loco) is relatively new to working with Docker and AWS Lambda, so there are bound to be a few bugs you can help fix 😉

