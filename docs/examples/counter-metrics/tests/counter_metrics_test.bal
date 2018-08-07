import ballerina/test;
import ballerina/io;
import ballerina/http;

boolean serviceStarted;

function startService() {
    serviceStarted = test:startServices("counter-metrics");
}

@test:Config {
    before: "startService",
    after: "stopService"
}
function testFunc() {
    // Invoking the main function
    endpoint http:Client httpEndpoint { url: "http://localhost:9090" };
    // Check whether the server has started
    test:assertTrue(serviceStarted, msg = "Unable to start the service");

    string response1 = "Order Processed!";

    // Send a GET request to the specified endpoint
    var response = httpEndpoint->get("/online-store-service/make-order");
    match response {
        http:Response resp => {
            var res = check resp.getTextPayload();
            test:assertEquals(res, response1);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

function stopService() {
    test:stopServices("counter-metrics");
}