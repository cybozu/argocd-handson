function(tag, message)
  [
    (import 'deployment.libsonnet')(tag, message),
    import 'service.libsonnet',
  ]
