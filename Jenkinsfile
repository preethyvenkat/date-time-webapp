pipeline {
    agent any

    environment {
        AWS_REGION   = 'us-east-1'
        ECR_REPO     = '141409473062.dkr.ecr.us-east-1.amazonaws.com/date-time-webapp'
        IMAGE_TAG    = "v${BUILD_NUMBER}"
        FULL_IMAGE   = "${ECR_REPO}:${IMAGE_TAG}"
        MANIFEST_REPO = 'git@github.com:preethyvenkat/date-time-webapp.git'
        TF_DIR       = 'infrastructure/terraform-eks-cluster'
    }

    stages {

        stage('Pre-Build Lint & Validate') {
            steps {
                sh '''
                    echo "🔍 Validating Dockerfile..."
                    if [ -f ./app/Dockerfile ]; then
                        docker run --rm -i hadolint/hadolint < ./app/Dockerfile || exit 1
                    fi

                    echo "🔍 Validating Kubernetes YAML..."
                    if command -v yamllint >/dev/null 2>&1; then
                        yamllint k8s/ || exit 1
                    else
                        echo "⚠️ yamllint not found, skipping YAML validation"
                    fi

                    echo "🔍 Validating Terraform configs..."
                    cd ${TF_DIR}
                    terraform init -backend=false
                    terraform validate || exit 1
                '''
            }   
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "🚧 Building Docker image: $FULL_IMAGE"
                    docker build -t $FULL_IMAGE ./app
                '''
            }
        }

        stage('Login to Amazon ECR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        mkdir -p ~/.aws
                        echo "[default]" > ~/.aws/credentials
                        echo "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
                        echo "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
                        echo "[default]" > ~/.aws/config
                        echo "region=$AWS_REGION" >> ~/.aws/config

                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    '''
                }
            }
        }

        stage('Create ECR Repository if not exists') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_REGION=$AWS_REGION

                        # Check if ECR repo exists, create if not
                        aws ecr describe-repositories --repository-names date-time-webapp --region $AWS_REGION || \
                        aws ecr create-repository --repository-name date-time-webapp --region $AWS_REGION
                        echo "✅ ECR repository is ready"
                    '''
                }
            }
        }
        stage('Tag Docker Image') {
            steps {
                sh '''
                    echo "🔖 Tagging Docker image: $FULL_IMAGE"
                    docker tag $FULL_IMAGE $ECR_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                sh 'docker push $FULL_IMAGE'
            }
        }

        stage('Terraform Init and Plan') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )]) {
                        withEnv([
                            "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID",
                            "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
                        ]) {
                            sh '''
                                terraform init
                                terraform plan -out=tfplan
                                echo "✅ Terraform plan created"
                            '''
                        }
                    }
                }
            }
        }

        stage('Terraform Apply (EKS)') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )]) {
                        withEnv([
                            "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID",
                            "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
                        ]) {
                            sh '''
                                terraform apply -auto-approve tfplan
                                echo "✅ Terraform applied successfully"
                            '''
                        }
                    }
                }
            }
        }

        stage('Install Argo CD on EKS') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    withEnv([
                        "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID",
                        "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
                    ]) {
                        sh '''
                            aws eks update-kubeconfig --region $AWS_REGION --name arm64-eks-cluster

                            until kubectl get nodes | grep -q 'Ready'; do
                              echo "⏳ Waiting for EKS nodes to be ready..."
                              sleep 10
                            done

                            kubectl create namespace argocd || true
                            kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
                            echo "✅ Argo CD installed"
                        '''
                    }
                }
            }
        }

        stage('Update Kubernetes Manifest in GitOps Repo') {
            steps {
                sshagent(credentials: ['github-creds']) {
                    sh '''
                        set -e
                        rm -rf manifests
                        git clone $MANIFEST_REPO manifests
                        cd manifests
                        git pull --rebase origin main

                        sed -i'' "s|image: .*|image: $FULL_IMAGE|" k8s/deployment.yaml

                        git config user.email "preevenkat@gmail.com"
                        git config user.name "Preethy Venkat"

                        if git diff --quiet; then
                            echo "No changes to commit"
                        else
                            git add k8s/deployment.yaml
                            git commit -m "Update image to $IMAGE_TAG"
                            git push origin main
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline completed successfully!"
            // Add Slack notification here
        }
        failure {
            echo "❌ Pipeline failed."
            // Add Slack alert here
        }
        cleanup {
            echo "🧹 Cleaning up workspace..."
            deleteDir()
        }
    }
}