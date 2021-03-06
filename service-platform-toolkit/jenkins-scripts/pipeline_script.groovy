node {
  echo 'Hello World'

  def mvnHome
  def dockerHome

  stage('Preparation') { // for display purposes
    // Get some code from a GitHub repository

    git 'https://github.com/jatin-desai/kubernetes_developer_env.git'

    // Get the Maven tool.
    mvnHome = tool 'maven'
    dockerHome = tool 'docker'
  }

  stage('Build Service') {
    sh "chmod +x ./service-platform-toolkit/jenkins/microservice_build.sh"
    sh "./service-platform-toolkit/jenkins/microservice_build.sh"
  }

  stage('Create Docker Image') {
    sh "chmod +x ./service-platform-toolkit/jenkins/microservice_docker.sh"
    sh "./service-platform-toolkit/jenkins/microservice_docker.sh"
  }

  stage('Generate Kubernetes Config') {
    sh "chmod +x ./service-platform-toolkit/jenkins/microservice_config.sh"
    sh "./service-platform-toolkit/jenkins/microservice_config.sh"
  }

  stage('Deploy to Kubernetes') {
    sh "chmod +x ./service-platform-toolkit/jenkins/microservice_kube_deploy.sh"
    sh "./service-platform-toolkit/jenkins/microservice_kube_deploy.sh"
  }

}
