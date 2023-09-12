resource "aws_dynamodb_table" "example_table" {
  name           = "StringOccur"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "itemId" # Change to your desired primary key
                # itemId: itemId,
                # appears: appears,
                # instring: inString,
                # count: count,
  attribute {
    name = "itemId"
    type = "S"
  } 
}

# Create a policy to allow lambda to access specific dynamo table to get put and get items.
# We can go crazy here and have 2 policies one for each lambda with the respective action,
# For this exercise we will suffice with one.
resource "aws_iam_policy" "dynamoDBLambdaPolicy" {
  name = "DynamoDBLambdaPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ],
        "Resource": [
          "${aws_dynamodb_table.example_table.arn}"
        ]
      }
    ]
}
EOF
}
