# Rocket - infrastructure

Rocket is a web platform built at Keus S.r.l. to run a catalogue of proprietary SaaS products from one place: orders, licences, contracts, invoices and the metrics of every product. This repository describes its AWS infrastructure as code, in OpenTofu. It accompanies the master's thesis *Design and Development of a Scalable Web Platform for Proprietary Software Product Tracking and Management Using Enterprise-Level Frameworks and Cloud Architecture* (Damiano Caon, University of Padua, Department of Information Engineering).

The code is a copy of the one Keus runs, prepared for public consultation. It deploys the demo on a separate AWS account in Ireland (`eu-west-1`), without custom domains and without external integrations. Every change made for that purpose carries the comment `Demo mode (INTEGRATIONS_ENABLED=false), not part of the original Rocket.`

Live demo: <https://d2c8lp2zkatd89.cloudfront.net> (the demo accounts are listed in the [frontend README](https://github.com/dcaon01/rocket-fe-thesis-demo#demo-accounts))

The other two parts of the platform:
- [rocket-fe-thesis-demo](https://github.com/dcaon01/rocket-fe-thesis-demo): the Angular interface;
- [rocket-be-thesis-demo](https://github.com/dcaon01/rocket-be-thesis-demo): the NestJS backend.

## Structure

- `be/`: the backend. Three Lambda functions (core, cognito, render) behind an HTTP API Gateway, the Cognito user pool, the SQS queues and the EventBridge bus of the integration with the products, the S3 buckets for files and packages, the SES identity and the email templates, and the IAM roles the backend's CI takes through GitHub OIDC.
- `fe/`: the frontend. A private S3 bucket served by a CloudFront distribution, and the role the frontend's CI takes to publish it.
- `shared/modules/`: the modules both use, such as `lambda-function`, `api-gateway`, `cognito`, `sqs-queue`, `cloudfront-cdn` and `github-oidc`.
- `bootstrap/`: the S3 bucket and DynamoDB lock table that hold the remote state of `be` and `fe`, created with CloudPosse's `tfstate-backend` module.
- `backend-configs/`: the backend settings `tofu init` reads to reach that state, one file per environment and component.

The OpenTofu workspace is the environment: `dev` and `prod` share the code and differ in the values of `locals.tf`. The DynamoDB tables of the application are not here, because Dynamoose creates them when the core starts.

In the demo, `integrations_enabled` defaults to `false`. Without it the SES identity on Keus's domain is not created, Cognito sends its invitations from its default address, no product queue is configured, and the core Lambda gets `INTEGRATIONS_ENABLED=false`.

## Order of the first deploy

1. `bootstrap/`: creates the state bucket and lock table for each environment and component.
2. `fe/`: creates the bucket and the distribution. Its output is the CloudFront address, which the backend needs for CORS and for the links in its documents.
3. `be/`, with `-var lambda_placeholder=true`: on an empty account no Lambda package exists on S3 yet, so the functions are created with a placeholder.
4. The CI of the backend repository builds the packages, uploads them and runs `tofu apply` from this repository with the real ones. From then on every deploy goes through the CI.

```bash
cd be
tofu init -backend-config=../backend-configs/dev-backend.tfbackend
tofu workspace select -or-create dev
tofu apply -var domain_name=<cloudfront-address> -var lambda_placeholder=true
```

Locally the AWS profile comes from `aws_profiles` in `variables.tf`. In CI no profile is used: the workflows take the roles in `github-oidc.tf` and the repositories hold no AWS key.

## Terms of use

This code is published with the consent of Keus S.r.l. for academic and evaluation purposes only, as a companion to the thesis above. All rights are reserved. The repository may be read, cloned and run to examine the work described in the thesis, but neither the code nor any part of it may be used, copied, modified or redistributed for commercial purposes. For any other use, contact the author through GitHub: https://github.com/dcaon01.
