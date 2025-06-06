pipeline {
    agent any

    tools {
        maven 'maven3'
    }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['blue', 'green'], description: 'Choose which environment to deploy: Blue or Green')
        choice(name: 'DOCKER_TAG', choices: ['blue', 'green'], description: 'Choose the Docker image tag for the deployment')
        booleanParam(name: 'SWITCH_TRAFFIC', defaultValue: false, description: 'Switch traffic between Blue and Green')
    }

    environment {
        IMAGE_NAME = "subrotosharma/bankapp"
        TAG = "${params.DOCKER_TAG}"
        SCANNER_HOME = tool 'sonar-scanner'
        KUBE_NAMESPACE = 'webapps'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/subrotosharma/Blue-Green-Deployment-with-CICD.git'
            }
        }

        stage('Compile') {
            steps {
                sh "mvn compile"
            }
        }

        stage('Tests') {
            steps {
                sh "mvn test -DskipTests=true"
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh "trivy fs --format table -o fs.html ."
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh "$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=Multitier -Dsonar.projectName=Multitier -Dsonar.java.binaries=target"
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Build') {
            steps {
                sh "mvn package -DskipTests=true"
            }
        }

        stage('Publish Artifact To Nexus') {
            steps {
                withMaven(
                    maven: 'maven3',
                    globalMavenSettingsConfig: 'settings.xml'  // Match ID from Jenkins managed files
                ) {
                    sh 'mvn deploy -DskipTests=true'
                }
            }
        }

        stage('Docker Build & Tag Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh "docker build -t ${IMAGE_NAME}:${TAG} ."
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image --format table -o image-scan.html ${IMAGE_NAME}:${TAG}"
            }
        }

        stage('Docker Push Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh "docker push ${IMAGE_NAME}:${TAG}"
                    }
                }
            }
        }

        stage('Deploy MySQL Deployment and Service') {
            steps {
                script {
                    withKubeConfig(
                        credentialsId: 'k8s-token',
                        serverUrl: 'https://3869C76F35091F8B57CD09F70E11CD30.gr7.us-east-1.eks.amazonaws.com',
                        namespace: "${KUBE_NAMESPACE}"
                    ) {
                        sh "kubectl apply -f mysql-ds.yml -n ${KUBE_NAMESPACE}"
                    }
                }
            }
        }

        stage('Deploy SVC-APP') {
            steps {
                script {
                    withKubeConfig(
                        credentialsId: 'k8s-token',
                        serverUrl: 'https://3869C76F35091F8B57CD09F70E11CD30.gr7.us-east-1.eks.amazonaws.com',
                        namespace: "${KUBE_NAMESPACE}"
                    ) {
                        sh """
                        if ! kubectl get svc bankapp-service -n ${KUBE_NAMESPACE}; then
                            kubectl apply -f bankapp-service.yml -n ${KUBE_NAMESPACE}
                        fi
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def deploymentFile = (params.DEPLOY_ENV == 'blue') ? 'app-deployment-blue.yml' : 'app-deployment-green.yml'
                    withKubeConfig(
                        credentialsId: 'k8s-token',
                        serverUrl: 'https://3869C76F35091F8B57CD09F70E11CD30.gr7.us-east-1.eks.amazonaws.com',
                        namespace: "${KUBE_NAMESPACE}"
                    ) {
                        sh "kubectl apply -f ${deploymentFile} -n ${KUBE_NAMESPACE}"
                    }
                }
            }
        }

        stage('Switch Traffic Between Blue & Green Environment') {
            when {
                expression { return params.SWITCH_TRAFFIC }
            }
            steps {
                script {
                    def newEnv = params.DEPLOY_ENV
                    withKubeConfig(
                        credentialsId: 'k8s-token',
                        serverUrl: 'https://3869C76F35091F8B57CD09F70E11CD30.gr7.us-east-1.eks.amazonaws.com',
                        namespace: "${KUBE_NAMESPACE}"
                    ) {
                        sh """
                        kubectl patch service bankapp-service -p '{"spec": {"selector": {"app": "bankapp", "version": "${newEnv}"}}}' -n ${KUBE_NAMESPACE}
                        """
                    }
                    echo "✅ Traffic switched to the ${newEnv} environment."
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def verifyEnv = params.DEPLOY_ENV
                    withKubeConfig(
                        credentialsId: 'k8s-token',
                        serverUrl: 'https://3869C76F35091F8B57CD09F70E11CD30.gr7.us-east-1.eks.amazonaws.com',
                        namespace: "${KUBE_NAMESPACE}"
                    ) {
                        sh """
                        kubectl get pods -l version=${verifyEnv} -n ${KUBE_NAMESPACE}
                        kubectl get svc bankapp-service -n ${KUBE_NAMESPACE}
                        """
                    }
                }
            }
        }
    }
}
