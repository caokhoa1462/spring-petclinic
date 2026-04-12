pipeline {
    agent any
    
    environment {
        DOCKER_HUB_USER = 'caokhoa1462'
        IMAGE_NAME = 'petclinic-app'
        // Tự động gán tag theo tên nhánh (main hoặc develop)
        IMAGE_TAG = "${BRANCH_NAME}-${BUILD_NUMBER}" 
        EC2_PUBLIC_IP = '13.250.238.57'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Security Scan: OWASP') {
            steps {
                sh 'chmod +x mvnw'
                sh './mvnw org.owasp:dependency-check-maven:check -Dformat=HTML'
            }
        }

        stage('Build Image') {
            steps {
                // Build với tag tương ứng với nhánh đang chạy
                sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Security Scan: Trivy') {
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.58.2 image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // ---- STAGE NÀY CHỈ CHẠY KHI LÀ NHÁNH MAIN ----
        stage('Push & Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
                sshagent(['ec2-ssh-key']) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_PUBLIC_IP} 'cd ~/petclinic && sudo docker compose pull && sudo docker compose up -d'"
                }
            }
        }

        // ---- STAGE NÀY CHỈ CHẠY KHI LÀ NHÁNH DEVELOP ----
        stage('Notify Success (Develop)') {
            when {
                branch 'develop'
            }
            steps {
                echo "Build và Quét bảo mật thành công cho nhánh DEVELOP. Sẵn sàng để Merge!"
            }
        }
    }
}