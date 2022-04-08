load('ext://min_k8s_version', 'min_k8s_version')
min_k8s_version('1.18.0')

trigger_mode(TRIGGER_MODE_MANUAL)

load('ext://namespace', 'namespace_create')
namespace_create('brigade-noisy-neighbor')
k8s_resource(
  new_name = 'namespace',
  objects = ['brigade-noisy-neighbor:namespace'],
  labels = ['brigade-noisy-neighbor']
)

docker_build(
  'brigadecore/brigade-noisy-neighbor', '.',
  only = [
    'config.go',
    'go.mod',
    'go.sum',
    'main.go'
  ]
)
k8s_resource(
  workload = 'brigade-noisy-neighbor',
  new_name = 'noisy-neighbor',
  labels = ['brigade-noisy-neighbor'],
)
k8s_resource(
  workload = 'noisy-neighbor',
  objects = ['brigade-noisy-neighbor:secret']
)

k8s_yaml(
  helm(
    './charts/brigade-noisy-neighbor',
    name = 'brigade-noisy-neighbor',
    namespace = 'brigade-noisy-neighbor',
    set = ['brigade.apiToken=' + os.environ['BRIGADE_API_TOKEN']]
  )
)
