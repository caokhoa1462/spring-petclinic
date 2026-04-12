pipeline {
    agent any
    
    environment {
        DOCKER_HUB_USER = 'caokhoa1462'
        IMAGE_NAME = 'petclinic-app'
        IMAGE_TAG = 'v2'
        EC2_PUBLIC_IP = '47.130.5.155' 
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        // --- STAGE 1: SCAN THE SOURCE CODE ---
        stage('Security Scan: OWASP') {
            steps {
                echo "Granting permissions  Maven Wrapper..."
                sh 'chmod +x mvnw'
                
                echo "Running OWASP Dependency Check..."
                sh './mvnw org.owasp:dependency-check-maven:check -Dformat=HTML'
            }
        }

        stage('Build Image') {
            steps {
                sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        // --- STAGE MỚI 2: SCAN DOCKER IMAGE'S SECURITY  ---
        stage('Security Scan: Trivy') {
            steps {
                echo "Đang chạy Trivy để quét Docker Image..."
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
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
                sshagent(['ec2-ssh-key']) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_PUBLIC_IP} 'cd ~/petclinic && sudo docker compose pull && sudo docker compose up -d'"
                }
            }
        }
    }
}