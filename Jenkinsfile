pipeline {
    agent none 
    
    // Global environment variables for AWS ECR authentication
    environment {
        AWS_ACCOUNT_ID = '916338043124' 
        AWS_REGION     = 'us-east-1'         
        ECR_REPO_NAME  = 'springboot-app'          
    }
    
    stages {
        stage('Checkout Code') {
            agent any
            steps {
                checkout scm
            }
        }
        
        stage('Build & Test') {
            agent {
                docker { image 'maven:3.9.6-eclipse-temurin-21' }
            }
            steps {
                echo 'Running Maven build and tests...'
                sh 'mvn clean package -Dmaven.repo.local=/tmp/m2'
            }
        }
        
        stage('SonarQube Analysis') {
            agent {
                docker { 
                    image 'maven:3.9.6-eclipse-temurin-21'
                    args '--net=host' 
                }
            }
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121:sonar -Dsonar.projectKey=springboot-jenkins-cicd -Dsonar.projectName="springboot-jenkins-cicd" -Dmaven.repo.local=/tmp/m2 -Dsonar.userHome=/tmp'
                }
                // FIX: Give Jenkins 15 seconds to safely register the Sonar background task ID metadata
                sleep time: 15, unit: 'SECONDS'
            }
        }
        
        stage('Quality Gate') {
            agent any 
            steps {
                echo 'Checking SonarQube Quality Gate status...'
                timeout(time: 10, unit: 'MINUTES') {
                    // This will now catch the webhook or fetch the completed status instantly
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
            // Uses the host agent directly to execute native Docker daemon commands 
            agent any 
            steps {
                echo 'Building and pushing Docker image to AWS ECR...'
                // Injecting AWS access keys stored inside the Jenkins credentials manager
                withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        # 1. Log into your private AWS ECR container registry backend
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        
                        # 2. Package and build the Docker image using your root Dockerfile
                        docker build -t ${ECR_REPO_NAME}:${BUILD_NUMBER} .
                        
                        # 3. Add AWS formatting tags to the constructed image layer
                        docker tag ${ECR_REPO_NAME}:${BUILD_NUMBER} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}://{ECR_REPO_NAME}:${BUILD_NUMBER}
                        docker tag ${ECR_REPO_NAME}:${BUILD_NUMBER} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}://{ECR_REPO_NAME}:latest
                        
                        # 4. Push both individual build logs and 'latest' tags directly into the repository registry
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}://{ECR_REPO_NAME}:${BUILD_NUMBER}
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}://{ECR_REPO_NAME}:latest
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
            echo 'Pipeline or Quality Gate failed.'
        }
    }
}
