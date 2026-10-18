pipeline {
    // Allows each stage to specify its own container agent
    agent any
    
    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        
        stage('Build & Test') {
            agent {
                docker {
                    // Runs the build and tests using Java 17
                    image 'maven:3.9.6-eclipse-temurin-17'
                    args '-v maven-repo:/root/.m2'
                }
            }
            steps {
                echo 'Running Maven build and tests on Java 17...'
                sh 'mvn clean package'
            }
        }
        
        stage('SonarQube Analysis') {
            agent {
                docker {
                    // Automatically spins up a fresh Java 21 container just for SonarQube
                    image 'maven:3.9.6-eclipse-temurin-21'
                    args '-v maven-repo:/root/.m2'
                }
            }
            steps {
                echo 'Running SonarQube analysis using Java 21...'
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121:sonar -Dsonar.projectKey=springboot-jenkins-cicd -Dsonar.projectName="springboot-jenkins-cicd"'
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Archive Artifacts') {
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