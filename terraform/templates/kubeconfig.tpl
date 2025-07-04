apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${cluster_ca_data}
    server: ${cluster_endpoint}
  name: arn:aws:eks:${region}:${account_id}:cluster/${cluster_name}
contexts:
- context:
    cluster: arn:aws:eks:${region}:${account_id}:cluster/${cluster_name}
    user: arn:aws:eks:${region}:${account_id}:cluster/${cluster_name}
  name: arn:aws:eks:${region}:${account_id}:cluster/${cluster_name}
current-context: arn:aws:eks:${region}:${account_id}:cluster/${cluster_name}
kind: Config
preferences: {}
users:
- name: arn:aws:eks:${region}:${account_id}:cluster/${cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      interactiveMode: Never
      args:
      - --region
      - ${region}
      - eks
      - get-token
      - --cluster-name
      - ${cluster_name}
