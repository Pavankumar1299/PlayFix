pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "abhishekshgit/react-app"
        // IP address comes from Terraform output
        DEPLOY_SERVER = "ubuntu@44.222.251.160" 
    }
y
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
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    
                    // FIXED LINE: We use "SYSTEM" instead of "%USERNAME%"
                    // This works because Jenkins is running as the System Service
                    bat 'icacls "%SSH_KEY%" /inheritance:r /grant:r SYSTEM:F'

                    sh """
                        ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" $SSH_USER@44.222.251.160 '
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