pipeline {
    agent any
    
    environment {
        DOCKER_HUB_USER = 'caokhoa1462'
        IMAGE_NAME = 'petclinic-app'
        IMAGE_TAG = "${BRANCH_NAME}-${BUILD_NUMBER}" 
        EC2_PUBLIC_IP = '47.130.5.155'
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
                // Thêm -Dformat=ALL để sau này plugin Jenkins đọc được biểu đồ
                sh './mvnw org.owasp:dependency-check-maven:check -Dformat=ALL'
            }
        }

        stage('Build Image') {
            steps {
                sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Security Scan: Trivy') {
            steps {
                echo "Đang chạy Trivy để quét Docker Image (với thời gian chờ dài hơn)..."
                sh """
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:0.58.2 image \
                    --timeout 15m \
                    --exit-code 0 \
                    --severity HIGH,CRITICAL \
                    ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Push & Deploy to Production') {
            when { branch 'main' }
            steps {
                // 1. Đẩy Image lên Docker Hub
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
                
                // 2. Deploy lên EC2
                sshagent(['ec2-ssh-key']) {
                    // MẸO: Sửa file docker-compose.yml để nó khớp với IMAGE_TAG vừa build
                    // Lệnh này tìm tên image cũ và thay bằng image mới kèm tag vừa tạo
                    sh "sed -i 's|image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:.*|image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}|g' docker-compose.yml"
                    
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_PUBLIC_IP} 'mkdir -p ~/petclinic'"
                    sh "scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${EC2_PUBLIC_IP}:~/petclinic/docker-compose.yml"
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_PUBLIC_IP} 'cd ~/petclinic && sudo docker compose pull && sudo docker compose up -d'"
                }
            }
        }

        stage('Notify Success (Develop)') {
            when { branch 'develop' }
            steps {
                echo "Build và Quét bảo mật thành công cho nhánh DEVELOP. Sẵn sàng để Merge!"
            }
        }
    }

    // Tầng 1: Lưu trữ báo cáo bảo mật
    post {
        always {
            // Lưu lại file báo cáo để có thể xem lại trên Jenkins
            archiveArtifacts artifacts: '**/target/dependency-check-report.html', allowEmptyArchive: true
            echo "Pipeline đã kết thúc. Hãy kiểm tra Artifacts để xem báo cáo bảo mật!"
        }
    }
}