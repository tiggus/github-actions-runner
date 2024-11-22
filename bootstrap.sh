#!/bin/bash

account="008971664666"
region="eu-west-2"
provider="github"
url="https://token.actions.githubusercontent.com"
audience="sts.amazonaws.com"
repo="monument-technology/infrastructure"

export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo $ACCOUNT

if [[ "$account" == "$ACCOUNT" ]] 
then
  echo "--- creating s3 bucket ---"
  aws s3api create-bucket \
    --bucket "terraform-$account" \
    --region $region \
    --create-bucket-configuration LocationConstraint=$region
else
  echo "error: account mismatch" >&2
fi



# https://stackoverflow.com/questions/48470049/build-a-json-string-with-bash-variables

echo "--- creating oidc json ---"
JSON_STRING=$( jq -n \
                  --arg URL "$url" \
                  --arg CID "$audience" \
                  '{Url: $URL, ClientIDList: [$CID]}' )
echo "${JSON_STRING}" | jq
echo $JSON_STRING > $provider-oidc.json


aws iam create-open-id-connect-provider \
    --cli-input-json file://$provider-oidc.json




# https://stackoverflow.com/questions/73102190/how-to-create-an-aws-iam-role-with-json-formatted-trust-policy-string-from-a-var


JSON_STRING=$(cat <<-END
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$account:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$repo:*"
                },
                "StringEquals": {
                    "$(echo $url | sed -e "s/\https:\/\///g"):aud": "$audience"
                }
            }
        }    
    ]
}
END
)

echo $JSON_STRING > $provider-role.json
cat $provider-role.json | jq

aws iam create-role \
    --role-name $provider-oidc \
    --assume-role-policy-document file://$provider-role.json


aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess \
    --role-name $provider-oidc
