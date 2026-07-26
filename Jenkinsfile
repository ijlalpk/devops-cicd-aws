// =============================================================================
// Jenkinsfile - your pipeline as code.
//
// This file lives in Git next to your app. That is the whole idea of
// "pipeline as code": the build process is versioned, reviewed and rolled back
// exactly like application code.
//
// Flow: GitHub push -> Jenkins wakes up -> test -> build image -> push to
//       Docker Hub -> SSH into the app server -> pull and restart -> verify.
//
// CREDENTIALS you must create in Jenkins first (Manage Jenkins > Credentials):
//   dockerhub-creds  : Username with password  (your Docker Hub login)
//   ec2-ssh-key      : SSH Username with private key (user: ubuntu or ec2-user)
//   app-server-ip    : Secret text (the PRIVATE IP of your app EC2 instance)
// =============================================================================

pipeline {
    // 'any' = run on the Jenkins controller itself. Fine for learning.
    // Real teams run builds on separate agent nodes.
    agent any

    environment {
        DOCKER_HUB_USER = 'ijlalpk'                       // <-- change to yours
        IMAGE_NAME      = 'devops-cicd-aws'
        // Jenkins gives every run a number. Using it as the tag means every
        // build is uniquely identifiable and you can roll back to any of them.
        IMAGE_TAG       = "v1.0.${BUILD_NUMBER}"
        FULL_IMAGE      = "${DOCKER_HUB_USER}/${IMAGE_NAME}"
        DEPLOY_USER     = 'ubuntu'                        // 'ec2-user' on Amazon Linux
    }

    options {
        timestamps()                                       // timestamp every log line
        buildDiscarder(logRotator(numToKeepStr: '10'))     // keep last 10 builds only
        timeout(time: 20, unit: 'MINUTES')                 // never hang forever
    }

    stages {

        stage('1. Checkout') {
            steps {
                echo "Pulling source code from GitHub..."
                checkout scm
                sh 'git log -1 --pretty=format:"Commit: %h by %an - %s"'
            }
        }

        stage('2. Test') {
            steps {
                echo "Running unit tests before building anything..."
                // Tests run inside a throwaway container so the Jenkins host
                // stays clean and the test environment is identical every time.
                sh '''
                    docker run --rm \
                      -v "$PWD":/src -w /src/app \
                      python:3.12-slim sh -c "
                        pip install --quiet -r requirements.txt &&
                        python -m pytest tests/ -v
                      "
                '''
            }
        }

        stage('3. Build image') {
            steps {
                echo "Building ${FULL_IMAGE}:${IMAGE_TAG}"
                sh "docker build -t ${FULL_IMAGE}:${IMAGE_TAG} -t ${FULL_IMAGE}:latest ."
                sh "docker images | grep ${IMAGE_NAME} | head -5"
            }
        }

        stage('4. Push to registry') {
            steps {
                echo "Pushing image to Docker Hub..."
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {
                    // --password-stdin keeps the password out of the build log.
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ''' + "${FULL_IMAGE}:${IMAGE_TAG}" + '''
                        docker push ''' + "${FULL_IMAGE}:latest" + '''
                        docker logout
                    '''
                }
            }
        }

        stage('5. Deploy to EC2') {
            steps {
                echo "Deploying to the application server over SSH..."
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'app-server-ip', variable: 'APP_HOST')
                ]) {
                    // The script is piped over stdin; the image and tag are
                    // passed as arguments to the remote bash process.
                    sh """
                        ssh -o StrictHostKeyChecking=no -i \$SSH_KEY ${DEPLOY_USER}@\$APP_HOST \\
                          "bash -s ${FULL_IMAGE} ${IMAGE_TAG}" < scripts/deploy.sh
                    """
                }
            }
        }

        stage('6. Verify') {
            steps {
                echo "Confirming the new version is actually serving traffic..."
                withCredentials([string(credentialsId: 'app-server-ip', variable: 'APP_HOST')]) {
                    script {
                        // Give the container a moment to finish booting.
                        sleep(time: 10, unit: 'SECONDS')
                        def code = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' http://\$APP_HOST/health",
                            returnStdout: true
                        ).trim()
                        if (code != '200') {
                            error("Health check failed with HTTP ${code}. Deployment is not healthy.")
                        }
                        echo "Health check passed: HTTP 200"
                    }
                }
            }
        }
    }

    // post{} always runs, whatever happened above.
    post {
        always {
            echo "Cleaning up dangling images on the Jenkins host..."
            sh 'docker image prune -f || true'
        }
        success {
            echo "SUCCESS - ${FULL_IMAGE}:${IMAGE_TAG} is live."
        }
        failure {
            echo "FAILED - check the stage above. Nothing was left half-deployed: deploy.sh rolls back automatically."
        }
    }
}
