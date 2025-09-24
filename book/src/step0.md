# Step0: 環境準備

まずはローカルに Argo CD を立て、自由に触れられる環境を準備しましょう。

## ローカル Kubernetes クラスタの構築

最初にローカルに Kubernetes クラスタを構築してください。構築には [kind] を使ってください。

[kind]: https://kind.sigs.k8s.io/

```bash
# kind のインストール手順は省略します。公式サイトの手順に従ってください。

# kind のクラスタを作成
kind create cluster

# `kind-control-plane` が存在していることを確認する
kubectl get node
```

※ 他の構築ツールでもほとんどの作業は実施可能なので、minikube などでもこのハンズオンを進めることができます。ただし、イメージのロードの部分だけは手順を置き換える必要があります。

## ローカル Argo CD の構築

[Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/) の1番から4番までの手順を行ってください。3番の手順でどれを選んだらいいかわからない人はとりあえず port forward にしておくのが安牌だと思います。

4番まで終わったらブラウザから argocd-server にアクセスしてみてください。UI が見れてログインできれば成功です。

## jsonnet のインストール

jsonnet の[公式のバイナリ](https://github.com/google/jsonnet/releases)をPATHの通った任意のディレクトリに突っ込んでください。

※ Kubernetes 環境に適用されるマニフェストは Argo CD がバンドルしている Go 版 jsonnet によって生成されるので、厳密な動作確認には Argo CD が使うのと同じ jsonnet を使うのが望ましいです。ハンズオンではそこまでの厳密さは必要ないと思うので、最新の C++ 版のバイナリを使うことにしています。

## 動作確認用に bastion をデプロイしておく

構築したサービスの動作を確認するために bastion (kubectl exec で入ってオペレーションするための踏み台) を用意しておきます。これはハンズオンのために便宜的に用意しているだけのもので、実運用では不要です。

以下のマニフェストを `kubectl apply` してください。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: bastion
spec:
  containers:
  - name: bastion
    image: cimg/base:stable
    command: ["sleep", "infinity"]
```
