pipeline {
    agent any
    environment {
        DOCKER_HUB_USER = 'caokhoa1462'
        IMAGE_NAME = 'petclinic-app'
        IMAGE_TAG = 'v2'
        EC2_PUBLIC_IP = '47.129.108.75'
    }
    stages {
        stage('Build Image') {
            steps {
                // Build lại image v2 từ Dockerfile Multi-stage
                sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        stage('Deploy to AWS EC2') {
            steps {
                // Jenkins dùng SSH để sang EC2 và chạy lệnh restart
                sshagent(['ec2-ssh-key']) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_PUBLIC_IP} 'cd ~/petclinic/petclinic-app && docker compose pull && docker compose up -d'"
                }
            }
        }
    }
}

 //Test CI/CD