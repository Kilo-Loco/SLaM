struct  FileTemplate {
    static func packageFileContents(packageName: String) -> String {
        """
        // swift-tools-version:5.3

        import PackageDescription

        let package = Package(
            name: "\(packageName)",
            platforms: [.macOS(.v11)],
            products: [
                .executable(
                    name: "\(packageName)",
                    targets: ["\(packageName)"]),
            ],
            dependencies: [
                .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.4.0"))
            ],
            targets: [
                .target(
                    name: "\(packageName)",
                    dependencies: [
                        .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                        .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime")
                    ]),
                .testTarget(
                    name: "\(packageName)Tests",
                    dependencies: ["\(packageName)"]),
            ]
        )
        """
    }
    
    static func mainFileContents() -> String {
        """
        import AWSLambdaEvents
        import AWSLambdaRuntime

        // MARK: - Run Lambda

        // Support API Gateway's Http API
        public typealias HttpApiRequest = APIGateway.V2.Request
        public typealias HttpApiResponse = APIGateway.V2.Response

        // set LOCAL_LAMBDA_SERVER_ENABLED env variable to "true" to start
        // a local server simulator which will allow local debugging

        Lambda.run { (context: Lambda.Context, request: HttpApiRequest, callback: @escaping (Result<HttpApiResponse, Error>) -> Void) in

            // here is my business code
            
            callback(.success(HttpApiResponse(statusCode: .ok, body: "Hello World")))
        }

        """
    }
    
    static func dockerFileContents() -> String {
        """
         FROM swift:5.3.3-amazonlinux2
         RUN yum -y install git zip
        """
    }
    
    static func packageScriptFileContents() -> String {
        """
        #!/bin/bash

        set -eu

        executable=$1

        target=.build/lambda/$executable
        rm -rf "$target"
        mkdir -p "$target"
        cp ".build/release/$executable" "$target/"
        
        # add the target deps based on ldd
        ldd ".build/release/$executable" | grep swift | awk '{print $3}' | xargs cp -Lv -t "$target"

        cd "$target"
        ln -s "$executable" "bootstrap"
        zip --symlinks lambda.zip *
        """
    }
    
    static func SAMTemplate(packageName: String) -> String {
        """
        AWSTemplateFormatVersion : '2010-09-09'
        Transform: AWS::Serverless-2016-10-31
        Description: A sample SAM template for deploying Lambda functions.

        Resources:

        # Lambda Function
          apiGatewayFunction:
            Type: AWS::Serverless::Function
            Properties:
              Handler: provided
              Runtime: provided
              CodeUri: ../.build/lambda/\(packageName)/lambda.zip
              
        # Add an API Gateway event source for the Lambda
              Events:
                HttpGet:
                  Type: HttpApi
                  Properties:
                    ApiId: !Ref lambdaApiGateway
                    Path: '/app'
                    Method: GET
                    
        # Instructs new versions to be published to an alias named "live".
              AutoPublishAlias: live

          lambdaApiGateway:
            Type: AWS::Serverless::HttpApi

        Outputs:
          LambdaApiGatewayEndpoint:
            Description: 'API Gateway endpoint URL.'
            Value: !Sub 'https://${lambdaApiGateway}.execute-api.${AWS::Region}.amazonaws.com/app'
        """
    }
    
    static func HTTPAPIEventTemplate() -> String {
        """
        {
          "version": "2.0",
          "routeKey": "$default",
          "rawPath": "/my/path",
          "rawQueryString": "parameter1=value1&parameter1=value2&parameter2=value",
          "cookies": [
            "cookie1",
            "cookie2"
          ],
          "headers": {
            "Header1": "value1",
            "Header2": "value1,value2"
          },
          "queryStringParameters": {
            "parameter1": "value1,value2",
            "parameter2": "value"
          },
          "requestContext": {
            "accountId": "123456789012",
            "apiId": "api-id",
            "authorizer": {
              "jwt": {
                "claims": {
                  "claim1": "value1",
                  "claim2": "value2"
                },
                "scopes": [
                  "scope1",
                  "scope2"
                ]
              }
            },
            "domainName": "id.execute-api.us-east-1.amazonaws.com",
            "domainPrefix": "id",
            "http": {
              "method": "POST",
              "path": "/my/path",
              "protocol": "HTTP/1.1",
              "sourceIp": "IP",
              "userAgent": "agent"
            },
            "requestId": "id",
            "routeKey": "$default",
            "stage": "$default",
            "time": "12/Mar/2020:19:03:58 +0000",
            "timeEpoch": 1583348638390
          },
          "body": "Hello from Lambda with JSON",
          "pathParameters": {
            "parameter1": "value1"
          },
          "isBase64Encoded": false,
          "stageVariables": {
            "stageVariable1": "value1",
            "stageVariable2": "value2"
          }
        }
        """
    }
}
