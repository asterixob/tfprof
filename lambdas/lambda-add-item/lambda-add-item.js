// lambda-add-item.js

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const { v4: uuidv4 } = require('uuid');

exports.handler = async (event) => {
    try {

        const requestBody = JSON.parse(event.body);

        const appears = requestBody.appears;
        const inString = requestBody.inString;

        // Validate that "appears" exists and has a length of 1
        if (!appears || appears.length !== 1) {
            return {
            statusCode: 400,
               body: JSON.stringify({ message: 'Invalid "appears" value' })
            };
        }

        // Count the number of times "appears" appears in "instring"
        const count = (inString.match(new RegExp(appears, 'g')) || []).length;

        // Generate a UUID
        const itemId = uuidv4();

        // Prepare Dynamo params
        const params = {
            "TableName": 'StringOccur',
            "Item": {
                "itemId": itemId,
                "appears": appears,
                "inString": inString,
                "count": count
            },
        };

        // add to db
        await dynamodb.put(params).promise();

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Item added successfully', itemId: itemId })
        };
    } catch (error) {
        console.log(error);
        return {
            statusCode: 500,
            body: JSON.stringify({message: "Internal counting Error" })
        };
    }
};
