import ballerina/log;
import ballerina/http;

@final string NAME = "NAME";
@final string AGE = "AGE";

@http:ServiceConfig {
    basePath: "/chat"
}
service<http:Service> chatAppUpgrader bind { port: 9090 } {

    // Upgrade from HTTP to WebSocket and define the service the WebSocket client needs to connect to.
    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/{name}",
            upgradeService: chatApp
        }
    }
    upgrader(endpoint caller, http:Request req, string name) {
        endpoint http:WebSocketListener wsEp;
        map<string> headers;
        wsEp = caller->acceptWebSocketUpgrade(headers);
        wsEp.attributes[NAME] = name;
        wsEp.attributes[AGE] = req.getQueryParams()["age"];
        string msg = "Hi " + name + "! You have succesfully connected to the chat";
        wsEp->pushText(msg) but { error e => log:printError("Error sending message", err = e) };
    }
}

// Stores the connection IDs of users who join the chat.
map<http:WebSocketListener> connectionsMap;

service<http:WebSocketService> chatApp {

    // Store the attributes of the user, such as username and age, once the user connects to the chat client, and
    // broadcast that the user has joined the chat.
    onOpen(endpoint caller) {
        string msg = string `{{getAttributeStr(caller, NAME)}} with age {{getAttributeStr(caller, AGE)}}
         connected to chat`;
        broadcast(connectionsMap, msg);
        connectionsMap[caller.id] = caller;
    }

    // Broadcast the messages sent by a user.
    onText(endpoint caller, string text) {
        string msg = string `{{getAttributeStr(caller, NAME)}}: {{text}}`;
        log:printInfo(msg);
        broadcast(connectionsMap, msg);
    }

    // Broadcast that a user has left the chat once a user leaves the chat.
    onClose(endpoint caller, int statusCode, string reason) {
        _ = connectionsMap.remove(caller.id);
        string msg = string `{{getAttributeStr(caller, NAME)}} left the chat`;
        broadcast(connectionsMap, msg);
    }
}

function broadcast(map<http:WebSocketListener> consMap, string text) {
    endpoint http:WebSocketListener ep;
    foreach id, con in consMap {
        ep = con;
        ep->pushText(text) but { error e => log:printError("Error sending message", err = e) };
    }
}

function getAttributeStr(http:WebSocketListener ep, string key) returns (string) {
    var name = <string>ep.attributes[key];
    return name;
}
