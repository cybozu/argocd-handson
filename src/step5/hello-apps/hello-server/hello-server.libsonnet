function(env, branch)
  {
    apiVersion: 'argoproj.io/v1alpha1',
    kind: 'Application',
    metadata: {
      name: env + '-hello-server',
      namespace: 'argocd',
      finalizers: [
        'resources-finalizer.argocd.argoproj.io',
      ],
    },
    spec: {
      project: 'default',
      // repoURL と path を自分のリポジトリのURLやパスに合わせて書き換えてください
      source: {
        repoURL: 'https://github.com/YOUR_NAME/argocd-handson',
        targetRevision: branch,
        path: 'src/step4/hello-server/kubernetes',
        directory: {
          jsonnet: {
            tlas: [
              {
                name: 'tag',
                value: '$ARGOCD_APP_REVISION',
              },
              {
                name: 'message',
                value: 'Hello (%s)' % env,
              },
            ],
          },
        },
      },
      destination: {
        server: 'https://kubernetes.default.svc',
        namespace: env + '-hello-server',
      },
      syncPolicy: {
        automated: {
          prune: true,
          selfHeal: true,
        },
      },
    },
  }
