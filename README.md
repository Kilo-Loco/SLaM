# Swift Lambda Maker

Swift Lambda Maker, aka SLaM, is an opiniated  CLI tool used for creating and packaging AWS Lambda functions written in Swift. It creates a new executable Swift Package where you can start coding your Lambda as well as package that Lambda as a zipped Docker image. It uses [SAM](https://aws.amazon.com/serverless/sam/) to deploy your AWS Lambda function and expose it through a REST API.

SAM deployment template is fully customisable and the trigger of the AWS Lambda function can be changed afterwards.

## Prerequisites
- [Swift 5.3+](https://swift.org/download/#releases)
- [Docker](https://www.docker.com/get-started)
- [SAM](https://aws.amazon.com/serverless/sam/)
- [AWS CLI](https://aws.amazon.com/cli/)

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

## Building and Packaging

Build and package your code. 

```bash
$ slam export
```

or individually build or package with 

```bash
$ slam build
$ slam package
```

> Run this command every time you need to package your updated Swift AWS Lambda function.

Once the export if finished, you can find the zipped AWS Lambda function at `pathToThisRepo/.build/lambda/[PROJECT_NAME]/lambda.zip`

### What's happening behind the scene ?

The build phase builds your code inside a Docker container running Amazon Linux. It produces a linux executable that the AWS Lambda service will be able to run.

The package phase craete a WIP file to be deployed on AWS Lambda. The zip files contains the Swift executable created during the build, but also all libraries required to run it on Amazon Linux. For example, the swift runtime and other third-party libraries linked to your code are included into the zip file.


## Deploying 

SLaM uses [SAM](https://aws.amazon.com/serverless/sam/) (Serverless Application Model) to easily deploy an AWS Lambda function.  The SAM template is located under `./scripts/sam.yml`. By default it hooks up your AWS Lambda function with an [HTTP API REST gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html). You're free to modify and redeploy other triggers to your AWS Lambda function.

```bash
$ slam deploy

🐿 Deploying with SAM...
🐿 ƛ AWS Lambda function deployed
You can now call your AWS Lambda at : https://k0001.execute-api.eu-west-1.amazonaws.com/app
```

To invoke your AWS Lambda function, you can use cURL:

```bash
$ curl https://k0001.execute-api.eu-west-1.amazonaws.com/app
Hello World
```

Everytime you change either the code of your AWS Lambda function, or the SAM template, you need to redeploy.

```bash
$ slam export && slam deploy
```

## Contributions and Support

SLaM is developed completely in the open, and contributions are welcomed. [Kilo Loco](https://github.com/kilo-loco) is relatively new to working with Docker and AWS Lambda, so there are bound to be a few bugs you can help fix 😉

[Sebastien Stormacq](https://github.com/sebsto/) added code and documentation to 

- update dependencies to latest version
- remove the need to name the docker image (uses the directory name)
- remove the need to prepare the docker container (now made automatically when calling `slam new`)
- add support for SAM and to deploy the AWS Lambda function (`slam deploy`)
- add sanity checks during scafolding, to ensure prerequisites are met (check installation of `docker`, `aws`, and `sam`CLIs)
- add preliminary support `slam invoke` to locally invoke and test your AWS Lambda function before to deploy it 

