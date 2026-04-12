pipeline {
    agent any
    
    environment {
        DOCKER_HUB_USER = 'caokhoa1462'
        IMAGE_NAME = 'petclinic-app'
        IMAGE_TAG = "${BRANCH_NAME}-${BUILD_NUMBER}" 
        EC2_PUBLIC_IP = '18.142.137.95'
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
                sh 'mkdir -p ${HOME}/.cache/trivy'

                sh """
                    docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    -v \$HOME/.cache/trivy:/root/.cache/trivy \
                    aquasec/trivy:0.58.2 image \
                    --format template --template "@/contrib/html.tpl" \
                    --timeout 15m \
                    --exit-code 0 \
                    --severity HIGH,CRITICAL \
                    ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} > trivy-report.html
                """
            }
        }

        stage('Push & Deploy to Production') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
                
                // 2. Deploy lên EC2
                sshagent(['ec2-ssh-key']) {
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
                echo "Build and security scan completed for the develop branch. You can merge to main now!"
            }
        }
    }

    post {
        always {
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target',
                reportFiles: 'dependency-check-report.html',
                reportName: 'OWASP Security Report'
            ])          
            publishHTML([
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: '.',
            reportFiles: 'trivy-report.html',
            reportName: 'Trivy Scan Report'
        ])
            archiveArtifacts artifacts: '**/target/dependency-check-report.html, trivy-report.html', allowEmptyArchive: true
        }
    }
}