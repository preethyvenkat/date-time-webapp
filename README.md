Deploy a web app that prints the current date and time (auto-refresh) using:
	•	Docker
	•	Jenkins (CI)
	•	Terraform (Infrastructure as Code)
	•	Kubernetes (Cluster Management)
	•	Argo CD (GitOps)
	•	Multipass VMs on macOS (aarch64)
	•	EKS cluster (aarch64 nodes)



Local Git Repo (App + Manifests)
          |
       [Push]
          ↓
     ┌────────┐
     │ Jenkins│ (in VM)
     └────────┘
          ↓
  ┌────────────────────┐
  │ Build & Push Docker│
  │ Image to ECR       │
  └────────────────────┘
          ↓
  ┌────────────────────┐
  │ Terraform provisions│
  │ ARM64 EKS Cluster   │
  └────────────────────┘
          ↓
     ┌────────┐
     │ Argo CD│ (in K8s)
     └────────┘
          ↓
     Deploys to EKS
          ↓
   Web App (shows time)


Step-by-Step Breakdown

1. Create Multipass VMs (ARM64) for Jenkins
	•	Set up Jenkins in a Multipass VM
	•	Install Docker, AWS CLI, Terraform, and kubectl inside it

2. Write Your Web App
	•	Simple Node.js, Python Flask, or static HTML + JS app
	•	Auto-refreshes and shows current time

3. Dockerize the App
	•	Create a Dockerfile
	•	Push to Amazon ECR (using Jenkins)

4. Write Kubernetes Manifests
	•	deployment.yaml and service.yaml for the app
	•	Point image to ECR

5. Setup Git Repositories
	•	app-repo: Source code + Dockerfile
	•	gitops-repo: K8s manifests

6. Configure Jenkins Pipeline
	•	Build image
	•	Push to ECR
	•	Commit K8s manifest updates to gitops-repo

7. Provision EKS (ARM64) using Terraform
	•	Use terraform-aws-eks module
	•	Specify ARM64-based Amazon Linux 2 AMIs or Bottlerocket

8. Install Argo CD in EKS
	•	Use Helm or kubectl
	•	Connect Argo CD to gitops-repo

9. Verify GitOps Flow
	•	Push code to app-repo
	•	Jenkins builds & updates gitops-repo
	•	Argo CD syncs manifests
	•	App auto-deploys to EKS



date-time-webapp/
├── app/
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
├── terraform/
│   └── main.tf (skeleton)
├── Jenkinsfile (if using Jenkins)
└── README.md
