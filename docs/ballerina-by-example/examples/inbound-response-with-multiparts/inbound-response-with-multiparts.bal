import ballerina.net.http;
import ballerina.mime;
import ballerina.io;

@http:configuration {port:9093}
service<http> multiparts {
    @http:resourceConfig {
        methods:["GET"],
        path:"/decode_in_response"
    }
    resource multipartReceiver (http:Connection conn, http:InRequest request) {
        endpoint<http:HttpClient> httpEndpoint {
            create http:HttpClient("http://localhost:9092", {});
        }
        http:OutRequest outRequest = {};
        http:InResponse inResponse = {};
        inResponse, _ = httpEndpoint.get("/multiparts/encode_out_response", outRequest);
        var parentParts, payloadError = inResponse.getMultiparts();
        http:OutResponse res = {};
        if (payloadError == null) {
            int i = 0;
            //Loop through parent parts.
            while (i < lengthof parentParts) {
                mime:Entity parentPart = parentParts[i];
                handleNestedParts(parentPart);
                i = i + 1;
            }
            res.setStringPayload("Nested Parts Received!");
        } else {
            res.statusCode = 500;
            res.setStringPayload(payloadError.message);
        }

        _ = conn.respond(res);
    }
}

//Given a parent part, get it's child parts.
function handleNestedParts (mime:Entity parentPart) {
    var childParts, _ = parentPart.getBodyParts();
    int i = 0;
    if (childParts != null) {
        io:println("Nested Parts Detected!");
        while (i < lengthof childParts) {
            mime:Entity childPart = childParts[i];
            handleContent(childPart);
            i = i + 1;
        }
    } else {
        //When there are no nested parts in a body part, handle the body content directly.
        io:println("Parent doesn't have children. So handling the body content directly...");
        handleContent(parentPart);
    }
}

//Handling body part content logic varies according to user's requirement.
function handleContent (mime:Entity bodyPart) {
    string contentType = bodyPart.contentType.toString();
    if (mime:APPLICATION_XML == contentType || mime:TEXT_XML == contentType) {
        //Extract xml data from body part and print.
        var xmlContent, _ = bodyPart.getXml();
        io:println(xmlContent);
    } else if (mime:APPLICATION_JSON == contentType) {
        //Extract json data from body part and print.
        var jsonContent, _ = bodyPart.getJson();
        io:println(jsonContent);
    } else if (mime:TEXT_PLAIN == contentType) {
        //Extract text data from body part and print.
        var textContent, _ = bodyPart.getText();
        io:println(textContent);
    } else if ("application/vnd.ms-powerpoint" == contentType) {
        //Get a byte channel from body part and write content to a file.
        var byteChannel, _ = bodyPart.getByteChannel();
        writeToFile(byteChannel);
        byteChannel.close();
        io:println("Content saved to file");
    }
}

function writeToFile (io:ByteChannel byteChannel) {
    string dstFilePath = "./files/savedFile.ppt";
    io:ByteChannel destinationChannel = getByteChannel(dstFilePath, "w");
    blob readContent;
    int numberOfBytesRead = 1;
    while (numberOfBytesRead != 0) {
        readContent, numberOfBytesRead = byteChannel.readBytes(10000);
        int numberOfBytesWritten = destinationChannel.writeBytes(readContent, 0);
    }
}

function getByteChannel (string filePath, string permission) (io:ByteChannel) {
    io:ByteChannel channel = io:openFile(filePath, permission);
    return channel;
}
