# terraform

Terraform setup for `zilch.me`.


## Setup

 1. Install `terraform` (e.g. with homebrew)

 2. Login to AWS, navigate to your IAM user, and generate an access token

 3. Create a `zilch` profile within `~/.aws/config`:

        [default]
        region = us-west-2

        [profile zilch]
        region = us-west-2

 4. Save the access token within `~/.aws/credentials`:

        [zilch]
        aws_access_key_id = <redacted>
        aws_secret_access_key = <redacted>
