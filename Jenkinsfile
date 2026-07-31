pipeline {
    agent any
    
    environment {
        PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
        DOCKER_CREDS = credentials('dockerhub-credentials') // Configured in Jenkins
        // IMPORTANT: Replace 'your-dockerhub-user' with your actual DockerHub username!
        IMAGE_NAME = "ghcr.io/dhanraj6377/jenkins-ci-project" 
        IMAGE_TAG = "${env.BUILD_ID}"
    }

    stages {
        stage('Determine Environment') {
            steps {
                script {
                    // We use a script block to safely run Groovy logic and assign dynamic variables
                    env.ACTIVE_ENV = sh(script: "kubectl get svc account-service -o=jsonpath='{.spec.selector.version}'", returnStdout: true).trim()
                    env.TARGET_ENV = env.ACTIVE_ENV == "blue" ? "green" : "blue"
                    echo "Currently Active: ${env.ACTIVE_ENV} | Target for Deployment: ${env.TARGET_ENV}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/dhanraj6377/jenkins-ci-project.git'
            }
        }

        stage('Build with Maven') {
            steps {
                echo "Building PiggyMetrics using Java 8 via Docker to prevent version mismatch..."
                sh 'docker run --rm -v "$(pwd)":/app -w /app maven:3.8.6-openjdk-8 mvn clean package -DskipTests'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                dir('account-service') {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "echo \$DOCKER_CREDS_PSW | docker login -u \$DOCKER_CREDS_USR --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to Inactive Environment') {
            steps {
                echo "Current Active Env: ${env.ACTIVE_ENV}. Deploying to: ${env.TARGET_ENV}"
                
                // Note: The extra '' after -i is required for macOS compatibility!
                sh "sed -i '' 's|IMAGE_TAG_PLACEHOLDER|${IMAGE_TAG}|g' k8s/services/account-service-${env.TARGET_ENV}.yaml"
                
                // Apply the deployment to the cluster
                sh "kubectl apply -f k8s/services/account-service-${env.TARGET_ENV}.yaml"
                
                // Wait for the new pods to be fully ready before proceeding
                sh "kubectl rollout status deployment/account-service-${env.TARGET_ENV} --timeout=120s"
            }
        }

        stage('Switch Traffic (Blue-Green)') {
            steps {
                echo "Switching live traffic to ${env.TARGET_ENV} environment..."
                // Patch the Kubernetes service to route to the new environment
                sh "kubectl patch service account-service -p '{\"spec\":{\"selector\":{\"version\":\"${env.TARGET_ENV}\"}}}'"
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed! Initiating safety rollback."
            echo "Ensuring traffic remains on or is rolled back to ${env.ACTIVE_ENV}..."
            sh "kubectl patch service account-service -p '{\"spec\":{\"selector\":{\"version\":\"${env.ACTIVE_ENV}\"}}}'"
        }
        success {
            echo "Deployment successful. Traffic is now live on ${env.TARGET_ENV}."
        }
    }
}