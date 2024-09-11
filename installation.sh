#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <docker-username> <docker-password> <docker-registry> <jenkinsfile-path>"
    exit 1
fi

DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2
DOCKER_REGISTRY=$3
JENKINSFILE_PATH=$4

# Function to install Minikube
install_minikube() {
    echo "Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    minikube start --driver=virtualbox
    minikube status
}

# Function to install kubectl
install_kubectl() {
    echo "Installing kubectl..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install kubectl /usr/local/bin/
    kubectl version --client
}

# Function to install Docker if not installed
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing Docker..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
    fi
}

# Log in to Docker
docker_login() {
    echo "Logging in to Docker registry..."
    echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin

    if [ $? -ne 0 ]; then
        echo "Docker login failed. Please check your credentials."
        exit 1
    fi

    echo "Docker login successful."
}

# Function to run Jenkins in Docker
run_jenkins() {
    echo "Running Jenkins in Docker..."
    docker run -d \
        --name jenkins \
        -p 8080:8080 \
        -p 50000:50000 \
        -v jenkins_home:/var/jenkins_home \
        -v /var/run/docker.sock:/var/run/docker.sock \
        jenkins/jenkins:lts
}

# Function to create Kubernetes credentials for Jenkins
create_kubernetes_credentials() {
    echo "Creating Kubernetes credentials..."
    
    # Create a service account
    kubectl create serviceaccount jenkins-sa

    # Bind the service account to the cluster-admin role
    kubectl create clusterrolebinding jenkins-sa --clusterrole=cluster-admin --serviceaccount=default:jenkins-sa

    # Get the token for the service account
    TOKEN=$(kubectl get secret $(kubectl get serviceaccount jenkins-sa -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode)

    echo "$TOKEN" > jenkins_kube_token.txt
    echo "Kubernetes token generated and saved to jenkins_kube_token.txt."
}

# Function to configure Jenkins Kubernetes cloud
configure_kubernetes_cloud() {
    echo "Configuring Jenkins Kubernetes cloud..."

    # Wait for Jenkins to be ready
    sleep 30

    # Configuring the Kubernetes cloud in Jenkins
    curl -X POST -u admin:admin "http://localhost:8080/jenkins/descriptorByName/org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud/configure" \
        --data-urlencode "name=minikube" \
        --data-urlencode "serverUrl=https://$(minikube ip):8443" \
        --data-urlencode "namespace=default" \
        --data-urlencode "credentialsId=jenkins-kube-credentials" \
        --data-urlencode "serverCertificate=" # Leave empty if using self-signed cert

    echo "Kubernetes cloud configured successfully."
}

# Function to import Jenkinsfile
import_jenkinsfile() {
    echo "Importing Jenkinsfile..."
    # Wait for Jenkins to be ready
    sleep 30  # Adjust time as needed
    curl -X POST -u admin:admin "http://localhost:8080/job/my-job/config.xml" --data-binary @"$JENKINSFILE_PATH" -H "Content-Type: application/xml"
}

# Function to trigger Jenkins pipeline
trigger_jenkins_pipeline() {
    echo "Triggering Jenkins pipeline..."
    curl -X POST -u admin:admin "http://localhost:8080/job/my-job/build"
    
    if [ $? -ne 0 ]; then
        echo "Failed to trigger Jenkins pipeline."
        exit 1
    fi

    echo "Jenkins pipeline triggered successfully."
}

# Main installation sequence
install_docker
docker_login
install_minikube
install_kubectl
run_jenkins
import_jenkinsfile
create_kubernetes_credentials
configure_kubernetes_cloud
trigger_jenkins_pipeline

echo "Jenkins installation and integration with Minikube completed! Access Jenkins at http://localhost:8080"