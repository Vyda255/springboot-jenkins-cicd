pipeline {
    agent none 
    
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
                    // CRITICAL FIX: Links the container network to your host network
                    args '--net=host' 
                }
            }
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121:sonar -Dsonar.projectKey=springboot-jenkins-cicd -Dsonar.projectName="springboot-jenkins-cicd" -Dmaven.repo.local=/tmp/m2'
                }
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
    }
    
    post {
        success {
            echo 'Pipeline and SonarQube Quality Gate passed successfully!'
        }
        failure {
            echo 'Pipeline or Quality Gate failed.'
        }
    }
}
