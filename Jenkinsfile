

pipeline {
    agent any

    environment {
        IMAGE_REPO = 'jananiparthasarathy/habitapp'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_SHORT}"
                }
            }
        }

        stage('Build and Test') {
            steps {
                sh 'mvn clean verify'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar -Dsonar.projectKey=habit-tracker -Dsonar.host.url=$SONAR_HOST_URL'
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                        docker build -t "$IMAGE_REPO:$IMAGE_TAG" .
                        docker push "$IMAGE_REPO:$IMAGE_TAG"
                        docker logout
                    '''
                }
            }
        }

        stage('Update Helm Configuration') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD'
                )]) {
                    sh '''
                        sed -i "s/^  tag: .*/  tag: \\"$IMAGE_TAG\\"/" habitapp/values.yaml

                        git config user.name "Jenkins"
                        git config user.email "jenkins@example.com"

                        git add habitapp/values.yaml
                        git commit -m "Update HabitApp image to $IMAGE_TAG"

                        AUTH=$(printf '%s' "$GIT_USERNAME:$GIT_PASSWORD" | base64 | tr -d '\\n')
                        git -c http.extraheader="AUTHORIZATION: basic $AUTH" push origin HEAD:main
                    '''
                }
            }
        }
    }

    post {
        always {
            junit testResults: 'target/surefire-reports/*.xml',
                  allowEmptyResults: true

            archiveArtifacts artifacts: 'target/*.jar',
                             allowEmptyArchive: true
        }
    }
}
