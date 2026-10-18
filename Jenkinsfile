pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-v maven-repo:/root/.m2'
        }
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                // Pulls code from the GitHub branch that triggered the build
                checkout scm
            }
        }
        
        stage('Build & Test') {
            steps {
                echo 'Running Maven build and tests inside Docker agent...'
                sh 'mvn clean package'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQubeServer') {
                    // Uses your GitHub repo name as the SonarQube project key and name
                    sh 'mvn sonar:sonar -Dsonar.projectKey=springboot-jenkins-cicd -Dsonar.projectName="springboot-jenkins-cicd"'
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    // Pauses the pipeline until SonarQube processes the report and returns a pass/fail
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                // Save the built JAR file so you can download it from Jenkins
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution finished.'
        }
        success {
            echo 'Pipeline and SonarQube Quality Gate passed successfully!'
        }
        failure {
            echo 'Pipeline or Quality Gate failed.'
        }
    }
}