resource "null_resource" "jenkins_gitops_vm" {
  provisioner "local-exec" {
    command = "multipass launch 22.04 --name jenkins-gitops-vm --cpus 2 --mem 4G --disk 10G"
  }
}
