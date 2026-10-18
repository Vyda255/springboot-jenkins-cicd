pipeline {
agent {
docker {
image 'maven:3.9.9-eclipse-temurin-17'
args '-v /tmp:/tmp'
}
}

environment {
    SONAR_PROJECT_KEY = 'springboot-jenkins-cicd'
}

stages {

    stage('Checkout') {
        steps {
            echo 'Checking out source code from GitHub...'
            checkout scm
        }
    }

    stage('Check Environment') {
        steps {
            echo 'Checking Java and Maven versions...'
            sh 'java -version'
            sh 'mvn -version'
        }
    }

    stage('Build and Test') {
        steps {
            echo 'Building Spring Boot application...'
            sh 'mvn -B clean verify'
        }
    }

    stage('SonarQube Analysis') {
        agent {
            docker {
                image 'maven:3.9.9-eclipse-temurin-21'
                args '-v /tmp:/tmp'
            }
        }
        steps {
            echo 'Running SonarQube analysis using Java 21...'

            sh 'java -version'
            sh 'mvn -version'

            withSonarQubeEnv('SonarQube') {
                sh '''
                    mvn -B \
                      org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922:sonar \
                      -Dsonar.projectKey=${SONAR_PROJECT_KEY}
                '''
            }
        }
    }
}

post {
    success {
        echo 'SUCCESS: Build, tests, and SonarQube analysis completed!'
    }

    failure {
        echo 'FAILED: Check the Jenkins Console Output to identify the error.'
    }

    always {
        echo 'Pipeline execution finished.'
    }
}

}
