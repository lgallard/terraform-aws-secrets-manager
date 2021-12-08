pipeline {
  agent any
   
   }
     stages {
     stage('checkout'){
         steps{
             checkout([$class: 'GitSCM', branches: [[name: 'J2EE']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '69236f43-f008-430d-8735-f08d372391f1', url: 'https://github.com/Kamalanadh-Reddy/onlinebookstore.git']]])
         }
         }
     stage('Build') {
        steps {
           sh "mvn clean package"
        }
    }
    stage('S3-upload') {
         steps {
            sh 'mv /var/lib/jenkins/workspace/bookcart/target/onlinebookstore-0.0.1-SNAPSHOT.war /var/lib/jenkins/workspace/bookcart/target/online.war'
            sh 'aws s3 cp /var/lib/jenkins/workspace/bookcart/target/online.war s3://bookcart/'
         }
      }
      stage('Deploy') {
         steps {
           sh 'aws s3 cp s3://bookcart/online.war .'
           sh  'scp online.war root@10.0.1.140:/opt/tomcat9/webapps/online.war'
          }
        }
   }
}
