pipeline {
  agent any

     stages {
     stage('checkout'){
         steps{
             checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: '6a1d1def-fbce-412d-bff1-bd9a4abbfc23', url: 'https://github.com/bablubharath/terraform-aws-secrets-manager.git']]])
         }
         }
     stage('Test') {
        steps {
           sh "terraform init"
           sh "terraform plan"
        }

        }
    }
}
