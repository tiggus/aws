assume_account "account-to-assume" "eu-west-2" "pat" "pass" "sso-account" "aws-user" "mfa-device" "cluster" "aws-role"

function assume_account(){
    base_login $2 $3 $4 $5 $6
    mfa_token $5 $7
    export ACCOUNT_ID=$1
    configure_account $9
    echo "aws eks --region $2 update-kubeconfig --name $8"
  }

 function base_login() {
  unset AWS_SESSION_TOKEN
  export AWS_DEFAULT_REGION=$1
  export AWS_ACCESS_KEY_ID=$2
  export AWS_SECRET_ACCESS_KEY=$3
  export ACCOUNT_ID=$4
  export aws_user=$5
}

function mfa_token() {
  echo "mfa token: "
  read token
  echo $1 $2
  eval $(aws sts get-session-token --serial-number arn:aws:iam::$1:mfa/$2 --token-code "${token}"|jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)
  export AWS_SESSION_TOKEN=\(.SessionToken)
  "')
}

function configure_account() {
    echo "assuming role"
    eval $(aws sts assume-role --role-arn arn:aws:iam::"${ACCOUNT_ID}":role/$1 --role-session-name admin-nonprod | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)
    export AWS_SESSION_TOKEN=\(.SessionToken)
    "')
    aws sts get-caller-identity
    env | grep -i AWS | sed 's/^/export /'
}
