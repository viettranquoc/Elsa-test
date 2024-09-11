pipeline {
    agent any

    environment {
        REGISTRY = 'https://hub.docker.com/<your docker hub user>'
        IMAGE_NAME = 'your-image-name'
        K8S_NAMESPACE = 'default'
        DOCKER_CREDENTIALS_ID = 'docker-credentials' // Put yourself docker hub credentials ID
        K8S_CREDENTIALS_ID = 'k8s-credentials' // Jenkins credentials ID for Kubernetes
        MANIFEST_REPO = 'https://github.com/viettranquoc/viettranquoc/viettran-test.git'  
        MANIFEST_DIR = 'k8s'  // Directory in the repo containing your Kubernetes manifests
    }

    stages {
        stage('Build') {
            steps {
                script {
                    // Checkout the code
                    checkout scm
                    
                    // Build the Docker image
                    docker.build("${REGISTRY}/${IMAGE_NAME}:be-${env.BUILD_ID}", "backend/")
                    docker.build("${REGISTRY}/${IMAGE_NAME}:fe-${env.BUILD_ID}")
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    // Login to Docker Registry
                    docker.withRegistry("${REGISTRY}", DOCKER_CREDENTIALS_ID) {
                        // Push the Docker image
                        docker.image("${REGISTRY}/${IMAGE_NAME}:be-${env.BUILD_ID}").push()
                        docker.image("${REGISTRY}/${IMAGE_NAME}:fe-${env.BUILD_ID}").push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Load Kubernetes credentials
                    withKubeConfig([credentialsId: K8S_CREDENTIALS_ID]) {
                        // Deploy the application to Kubernetes
                        sh "git clone ${MANIFEST_REPO} deployment && cd deployment"
                        sh "cd backend"
                        sh "kubectl set image deployment/backend ${K8S_DEPLOYMENT_NAME}=${REGISTRY}/${IMAGE_NAME}:be-${env.BUILD_ID} -n ${K8S_NAMESPACE}"
                        sh "kubectl rollout status deployment/backend -n ${K8S_NAMESPACE}"
                        sh "cd ../frontend"
                        sh "kubectl set image deployment/frontend ${K8S_DEPLOYMENT_NAME}=${REGISTRY}/${IMAGE_NAME}:fe-${env.BUILD_ID} -n ${K8S_NAMESPACE}"
                        sh "kubectl rollout status deployment/frontend -n ${K8S_NAMESPACE}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment was successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}