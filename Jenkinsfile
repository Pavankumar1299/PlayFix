pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "your-dockerhub-username/react-app"
        // IP address comes from Terraform output
        DEPLOY_SERVER = "ubuntu@<YOUR_EC2_IP_ADDRESS>" 
    }

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $DOCKER_IMAGE:latest .'
                }
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    sh 'docker push $DOCKER_IMAGE:latest'
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) { // You need the SSH Agent plugin
                    sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} '
                            docker pull ${DOCKER_IMAGE}:latest
                            docker stop react-app || true
                            docker rm react-app || true
                            docker run -d -p 80:80 --name react-app ${DOCKER_IMAGE}:latest
                        '
                    """
                }
            }
        }
    }
}