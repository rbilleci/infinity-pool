
# Infinity Pool Sample Application

## Introduction

This is a guide to setting up the Infinity Pool sample application.

## Deploying the Infinity Pool Application

### 1. Get an AWS Account

A prerequisite to deploying the Infinity Pool application is to have an AWS Account. 
The application is deployed to the eu-west-1 region by default.
You will need to create an ACCESS KEY and SECRET ACCESS KEY.  These will be configured as secrets for GitHub Actions. 

### 2. Configuring secrets GitHub for GitHub Actions

Configure the following GitHub Secrets. These are required to deploy the infinity pool application to your AWS account. 
For information on how to configure secrets in GitHub Actions [here.](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)

    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY

# Testing CI/CD Locally

You can test the CI/CD pipeline locally by installing [Act](https://nektosact.com/introduction.html). 

- You'll need to create a `.secrets` file in the project directory. The `.secrets` file is in the `.gitignore` and
should not be checked-in, since it contains the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
- There is also a `.env` file that references the AWS_REGION environment variable. This is needed for pushing images to
  the AWS ECR Repository.

# References

1. [GitHub Actions Tutorial](https://www.youtube.com/watch?v=YLtlz88zrLg) 
2. [Act](https://nektosact.com/introduction.html), for testing GitHub Actions locally. 