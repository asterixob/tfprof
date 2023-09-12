// lambda-retrieve-item.js

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {

    try {
        //get itemId from path paramter /get-number-of-occurrences/{itemId}
        const itemId = event.pathParameters.itemId;

        // prepare dynamo params
        const params = {
            "TableName": "StringOccur",
            "Key": {
                "itemId": itemId
            },
        };

        // perform lookup in dynamo
        const result = await dynamodb.get(params).promise();
        const item = result.Item;

        if (!item) {
            return {
                statusCode: 404,
                body: JSON.stringify({ error: 'Item not found' })
            };
        }

        return {
            statusCode: 200,
            body: JSON.stringify({count: item.count})
        };
    } catch (error) {
        console.log(error);
        return {
            statusCode: 500,
            body: JSON.stringify({message: "Internal occurrence Error" })
        };
    }
};
