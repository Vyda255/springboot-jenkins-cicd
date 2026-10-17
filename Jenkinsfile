pipeline {

    // Use a Docker container as the build environment.
    agent {
        docker {
            image 'maven:3.9.9-eclipse-temurin-17'
        }
    }

    stages {

        // Confirm Java and Maven are available.
        stage('Check Environment') {
            steps {
                sh 'java -version'
                sh 'mvn -version'
            }
        }

        // Retrieve the configured source revision.
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Compile, test, package, and verify the application.
        stage('Build and Test') {
            steps {
                sh 'mvn clean verify'
            }
        }
    }

    // Display the pipeline outcome.
    post {
        success {
            echo 'Build completed successfully!'
        }

        failure {
            echo 'Build failed. Check the Jenkins console output.'
        }
    }
}

