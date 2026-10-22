pipeline {
    agent none

    // Your AWS environment variables remain hidden securely.
    // Jenkins pulls AWS_ACCOUNT_ID, AWS_REGION, and ECR_REPO_NAME 
    // directly from your Jenkins Global Environment Variables.

    stages {

        stage('Checkout Code') {
            agent any
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            agent {
                docker {
                    // Configured to use Java 17 to match your production Dockerfile configuration
                    image 'maven:3.9.6-eclipse-temurin-17'
                    // CRUCIAL WEBHOOK FIX: Grants root write permissions inside the container 
                    // to prevent permission crashes triggered by changing the Jenkins URL context
                    args '-u root'
                }
            }
            steps {
                echo 'Running Maven build and tests...'
                sh 'mvn clean package -Dmaven.repo.local=/tmp/m2'
            }
        }

        stage('SonarQube Analysis') {
            agent {
                docker {
                    // Retained Java 21 execution context for the Sonar scanner tool compatibility
                    image 'maven:3.9.6-eclipse-temurin-21'
                    args '--net=host'
                }
            }
            steps {
                echo 'Running SonarQube analysis...'

                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121:sonar \
                        -Dsonar.projectKey=springboot-jenkins-cicd \
                        -Dsonar.projectName=springboot-jenkins-cicd \
                        -Dmaven.repo.local=/tmp/m2 \
                        -Dsonar.userHome=/tmp
                    '''
                }

                sleep time: 15, unit: 'SECONDS'
            }
        }

        stage('Quality Gate') {
            agent any
            steps {
                echo 'Checking SonarQube Quality Gate status...'

                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Archive Artifacts') {
            agent any
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Build & Push to ECR') {
            agent any
            steps {
                echo 'Building and pushing Docker image to AWS ECR...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        # Configure AWS region dynamically from Jenkins global env
                        export AWS_DEFAULT_REGION="${AWS_REGION}"

                        # Define the ECR registry and image names using injected variables
                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        ECR_IMAGE="${ECR_REGISTRY}/${ECR_REPO_NAME}"

                        # 1. Log in to Amazon ECR
                        aws ecr get-login-password --region "${AWS_REGION}" | \
                        docker login \
                            --username AWS \
                            --password-stdin "${ECR_REGISTRY}"

                        # 2. Build the Docker image
                        docker build -t "${ECR_REPO_NAME}:${BUILD_NUMBER}" .

                        # 3. Tag the image with its build number
                        docker tag \
                            "${ECR_REPO_NAME}:${BUILD_NUMBER}" \
                            "${ECR_IMAGE}:${BUILD_NUMBER}"

                        # 4. Tag the image as latest
                        docker tag \
                            "${ECR_REPO_NAME}:${BUILD_NUMBER}" \
                            "${ECR_IMAGE}:latest"

                        # 5. Push the build-number image to ECR
                        docker push "${ECR_IMAGE}:${BUILD_NUMBER}"

                        # 6. Push the latest image to ECR
                        docker push "${ECR_IMAGE}:latest"

                        echo "Docker images pushed successfully to ${ECR_IMAGE}"
                    '''
                }
            }
        }

        stage('Deploy to AWS ECS (Fargate)') {
            agent any
            steps {
                echo 'Notifying ECS Fargate Cluster to roll out the latest ECR image...'
                
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e
                        export AWS_DEFAULT_REGION="${AWS_REGION}"

                        # Triggers the Fargate service to perform a rolling replacement deployment
                        aws ecs update-service \
                            --cluster "springboot-cluster" \
                            --service "springboot-service" \
                            --force-new-deployment
                        
                        echo "Fargate rolling deployment triggered successfully!"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline, SonarQube Quality Gate, and ECR Push passed successfully!'
        }

        failure {
            echo 'Pipeline or Quality Gate failed. Check the console output for details.'
        }
    }
}
