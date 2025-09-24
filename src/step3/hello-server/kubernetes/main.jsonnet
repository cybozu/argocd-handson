function(tag)
  [
    (import 'deployment.libsonnet')(tag),
    import 'service.libsonnet',
  ]
