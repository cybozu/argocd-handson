function(tag)
  {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: 'hello-server',
      labels: {
        'app.kubernetes.io/name': 'hello-server',
      },
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: {
          'app.kubernetes.io/name': 'hello-server',
        },
      },
      template: {
        metadata: {
          labels: {
            'app.kubernetes.io/name': 'hello-server',
          },
        },
        spec: {
          containers: [
            {
              name: 'hello-server',
              image: 'docker.example.com/hello-server:' + tag,
              imagePullPolicy: 'Never',
              ports: [
                {
                  name: 'http',
                  containerPort: 8080,
                },
              ],
              livenessProbe: {
                httpGet: {
                  port: 'http',
                  path: '/health',
                },
              },
              readinessProbe: {
                httpGet: {
                  port: 'http',
                  path: '/ready',
                },
              },
              resources: {
                requests: {
                  memory: '100Mi',
                  cpu: '0.1',
                },
                limits: {
                  memory: '100Mi',
                  cpu: '0.1',
                },
              },
              securityContext: {
                readOnlyRootFilesystem: true,
              },
              env: [
                {
                  name: 'GOMAXPROCS',
                  value: '1',
                },
              ],
            },
          ],
        },
      },
    },
  }
