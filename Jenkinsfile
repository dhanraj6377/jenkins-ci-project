pipeline {
    agent any
    
    environment {
        DOCKER_CREDS = credentials('dockerhub-credentials') // Configured in Jenkins
        IMAGE_NAME = "your-dockerhub-user/account-service"
        IMAGE_TAG = "${env.BUILD_ID}"
        // Dynamically find which environment is currently active
        ACTIVE_ENV = sh(script: "kubectl get svc account-service -o=jsonpath='{.spec.selector.version}'", returnStdout: true).trim()
        TARGET_ENV = ACTIVE_ENV == "blue" ? "green" : "blue"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/sqshq/piggymetrics.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
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
                echo "Current Active Env: ${ACTIVE_ENV}. Deploying to: ${TARGET_ENV}"
                // Replace placeholder in YAML with actual built tag
                sh "sed -i 's|IMAGE_TAG_PLACEHOLDER|${IMAGE_TAG}|g' k8s/services/account-service-${TARGET_ENV}.yaml"
                
                // Apply the deployment to the cluster
                sh "kubectl apply -f k8s/services/account-service-${TARGET_ENV}.yaml"
                
                // Wait for the new pods to be fully ready before proceeding
                sh "kubectl rollout status deployment/account-service-${TARGET_ENV} --timeout=120s"
            }
        }

        stage('Switch Traffic (Blue-Green)') {
            steps {
                echo "Switching live traffic to ${TARGET_ENV} environment..."
                // Patch the Kubernetes service to route to the new environment
                sh "kubectl patch service account-service -p '{\"spec\":{\"selector\":{\"version\":\"${TARGET_ENV}\"}}}'"
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed! Initiating safety rollback."
            echo "Ensuring traffic remains on or is rolled back to ${ACTIVE_ENV}..."
            sh "kubectl patch service account-service -p '{\"spec\":{\"selector\":{\"version\":\"${ACTIVE_ENV}\"}}}'"
        }
        success {
            echo "Deployment successful. Traffic is now live on ${TARGET_ENV}."
            // Optional: Scale down the old deployment to save cluster resources
            // sh "kubectl scale deployment account-service-${ACTIVE_ENV} --replicas=0"
        }
    }
}