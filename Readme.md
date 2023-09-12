
# Creating the api gw and lambdas

Make sure u have aws access keys and secret (optional token) in the terminal session

terafrom init  
terraform plan  
terraform apply  

The output 'api_url' should be used as below in the curl commands

Outputs:  
api_url = "https://kqjis00oxi.execute-api.us-east-1.amazonaws.com/prod"

# Calling the API's

Using curl to add item to dynamo

curl --location 'https://kqjis00oxi.execute-api.us-east-1.amazonaws.com/prod/calculate-number-of-occurrences' \\  
--header 'Content-Type: application/json' \\  
--data '{"appears": "z", "inString": "sdffszzzzdfzz" }'  

Output  
{"message":"Item added successfully","itemId":"5578e930-d4c2-4aa0-bd02-841f47843a2f"}%

Using curl to Retrieve the count of the added item  

curl --location 'https://kqjis00oxi.execute-api.us-east-1.amazonaws.com/prod/get-number-of-occurrences/5578e930-d4c2-4aa0-bd02-841f47843a2f'

Output  
{"count":6}%