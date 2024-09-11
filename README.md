# Assessment Report

## Overview

This is detailed document on how to have the app running. Assume that your machine is Ubuntu 18.x and have Docker Engine running.

## Prerequisites

Follow the instructions below:
1. Install the minikube in the [1.minikube.md](1.minikube.md)
2. Clone the repository [2.clone_repository.md](2.clone_repository.md)
3. Install the Jenkins by docker [5.1.install_jenkins.md](5.1.install_jenkins.md)
4. Import the Jenkins pipeline [5.2.import_pipeline.md](5.2.import_pipeline.md)
5. Trigger the pipeline

## Automation

For apply the automation, please run this:

```bash
chmod +x installation.sh
./installation.sh <docker-username> <docker-password> <docker-registry> <jenkinsfile-path>
```