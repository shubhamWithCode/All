pipeline {
    agent any
    tools{
        maven 'maven'
    }
    stages{
        stage('Build Maven'){
            steps{
                git 'https://github.com/shubhamWithCode/DevOps-cicd-project.git'
                sh 'mvn clean install'
            }
        }
        stage('Build docker image'){
            steps{
                script{
                    sh 'docker buildx build -t vickygaikwad41996/mydockerimages .'
                }
            }
        }
        stage('Push image to Hub'){
            steps{
                script{
                   withCredentials([string(credentialsId: 'dockerhub-pwd', variable: 'dockerhubpwd')]) {
                   sh 'docker login -u vickygaikwad41996@gmail.com -p ${dockerhubpwd}'

}
                   sh 'docker push vickygaikwad41996/mydockerimages'
                }
            }
        }
        stage('EKS and Kubectl configuration'){
            steps{
                script{
                    sh 'aws eks update-kubeconfig --region ap-south-1 --name nike-cluster'
                }
            }
        }
        stage('Deploy to k8s'){
            steps{
                script{
                    sh 'kubectl apply -f deploymentservice.yaml'
                }
            }
        }
    }
}