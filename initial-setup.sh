
ALL COMMANDS SHOULD BE EXECUTED ON Capstone-Project SERVER (we can call this as "jenkins server")
**************************************

install.sh
**************************************

#Install jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt install -y awscli
sudo apt-get install jenkins -y

# Update existing list of packages
sudo apt update

# Install docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# Update the package database with Docker packages
sudo apt update
sudo apt install -y docker-ce
sudo usermod -aG docker $USER
# Add a new user 'jenkins'
sudo adduser --system --group --shell /bin/bash jenkins
# Add 'jenkins' user to the 'docker' group
sudo usermod -aG docker jenkins

#Install kubectl
curl -LO "https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin
sudo mkdir /var/lib/jenkins/.kube /var/lib/jenkins/.aws
sudo touch /var/lib/jenkins/.kube/config
sudo touch /var/lib/jenkins/.aws/credentials
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chown -R jenkins:jenkins /var/lib/jenkins/.aws
sudo chmod 600 /var/lib/jenkins/.kube/config


#Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
./get_helm.sh --version v3.8.2
rm get_helm.sh

#Install java
sudo apt update
sudo apt install openjdk-17-jre -y
java -version

#Install mysql client
sudo apt-get update
sudo apt-get install -y mysql-client

sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl restart docker
#sudo systemctl status jenkins

sudo cat /var/lib/jenkins/secrets/initialAdminPassword


**************************************
1. Add credential file with the keys on jenkins server and run --> 

aws eks update-kubeconfig --name capstone-humber --region us-east-1 (Add role to ec2)

2. Apply cluster-autoscaler.yaml file from devops repo on jenkins server 

kubectl apply -f /var/lib/jenkins/workspace/backend/manifest_files/cluster-autoscaler.yaml

3. create setup.sql file and copy content for this file from git repo cloud-inventory-backend/blob/master/src/main/resources/setup.sql

--> sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_general_ci/g' setup.sql
--> mysql -h rds-instance.cfncvcy7g4w8.us-east-1.rds.amazonaws.com -u myrdsuser -p  < setup.sql
#Password = myrdspassword

3. In jenkins, Go to manage jenkins and add github credentials for github where you have backend, frontend and devops repositories 

**************************************

ARGOCD SETUP STEPS----> run script from root user from jenkins server

**********************
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3: Expose ArgoCD API server (for demo purposes, we'll use a LoadBalancer service)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Step 4: Install the ArgoCD CLI
# (Assuming you're on an amd64 architecture. For other architectures, you might need to adjust the URL.)
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

echo "ArgoCD installation is complete."
echo "ArgoCD Password is ------------>"
echo $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

**************************************



kubectl get pods --all-namespaces | grep Evicted | awk '{print $2 " --namespace=" $1}' | xargs kubectl delete pod

