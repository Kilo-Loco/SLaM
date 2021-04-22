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
