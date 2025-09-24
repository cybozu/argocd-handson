# Step5: app-of-apps

Step4 までは Application リソースは手動で適用していました。しかし、サービスの種類が増えたり環境の数が増えたりすると適用すべき Application リソースの数も掛け算で増えていきます。これでは頻繁に手動手順を行う必要があり、あまり望ましい状態とは言えません。

実は Application リソースも単なる Kubernetes のリソースであり、Argo CD によってデプロイすることができます。つまり、Application を作成する Application を作ることができます。この考え方を app-of-apps と言います。

app-of-apps の考え方を採用すると、Kubernetes クラスタごとにひとつだけ手動で Application を適用すればよくなります。他の Application は、この Application によって自動的にデプロイされます。

他の Application リソースをデプロイする Application リソースは慣習的に `*-apps` と名付けられます。

大規模な Kubernetes クラスタの場合、app-of-apps の階層を多段にすることがあります。例えば サイボウズの Kubernetes 環境では以下のように Application が３層構造になっています(※)。それぞれの Application は一個下の階層の Application をデプロイし、最下層の Application は Deployment や Service といった具体的なリソースをデプロイします。

| Application | 何個あるのか | 管理者
| ----------- | ------------- | ----
| `root-app` | Kubernetes クラスタごとにひとつ | Kubernetes クラスタの管理者
| `*-apps` | (Kubernetes cluster, チーム) ごとにひとつ | そのチームに属する人
| サービスごとの Application | (Kubernetes cluster, 環境, サービス) ごとにひとつ | 同上

※ 実際にはもっと複雑ですが、このハンズオンでは単純化して説明しています。

## app-of-apps を導入する

それでは hello-server も app-of-apps に移行してみましょう。このハンズオンでは単純化のために app-of-apps の階層は２層にします。つまり、root-app が直接 `{dev,staging,prod}-hello-server` をデプロイする構成にします。

まず、Step4 で作ったリソースを削除して環境をキレイにしておきます。

```bash
argocd app delete dev-hello-server
argocd app delete staging-hello-server
argocd app delete prod-hello-server
```

次に、hello-apps リポジトリ側の準備をします。まず、ディレクトリレイアウトを少し変えましょう。hello-apps リポジトリのトップに hello-server ディレクトリを作成し、既存のファイルをすべてその下に移動させます。

```bash
mkdir hello-server
git mv dev prod staging hello-server.libsonnet hello-server
```

次にルートとなる Application を作ります。このハンズオンでは一つの Kubernetes クラスタの中にすべての環境を収めているため、ルートとなる Application はひとつで十分です。

hello-apps リポジトリのトップに root-app というディレクトリを作成し、その下に root-app.yaml という名前で Application のマニフェストを配置します。

```bash
mkdir root-app
editor root-app/root-app.yaml
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  # source と path は自分のリポジトリのURLやパスに合わせて書き換えてください
  source:
    repoURL: https://github.com/YOUR_NAME/argocd-handson
    targetRevision: main
    path: step5/hello-apps/hello-server
    directory:
      # サブディレクトリにある *.jsonnet もデプロイ対象に含める
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    # ここで指定した namespace よりも各マニフェストに書かれている .metadata.namespace のほうが優先される。
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      limit: 30
```

それでは、root-app をデプロイしてみましょう。

```bash
# Application が存在しないことを確認しておく
argocd app list

# root-app を作成
argocd app create -f root-app/root-app.yaml

# root-app が {dev,staging,prod}-hello-server を作成してくれるので
# ある程度待つと Application が4つ表示されるようになる
argocd app list

# Pod や Deployment などもそれぞれの namespace に作成されている
kubectl get all -n prod-hello-server
```

これで app-of-apps の導入ができました。`{dev,staging,prod}-hello-server` が Argo CD によって管理されるようになったため、Git 上でマニフェストが更新されれば自動的に対応する環境にデプロイされます。手動でのオペレーションは必要ありません (このハンズオンの環境では `argocd app sync ` を手で打つ必要がありますが)。

唯一 root-app だけは更新時に手動で `argocd app create --upsert` する必要があります。しかし root-app はめったに変更しないでしょうから、コストとしては許容範囲内だと思います。
