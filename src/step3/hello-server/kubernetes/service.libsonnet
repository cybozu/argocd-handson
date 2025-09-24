{
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    name: 'hello-server',
  },
  spec: {
    selector: {
      'app.kubernetes.io/name': 'hello-server',
    },
    ports: [
      {
        port: 80,
        targetPort: 'http',
      },
    ],
  },
}
