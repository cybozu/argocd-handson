# Step1: kubectl apply でデプロイする

まずは Argo CD を使わずに普通にサービスをデプロイしてみます。

## Git リポジトリを作る

GitHub に新しく Git リポジトリを作成してください。名前は何でもいいですが、ここでは `hello-server` という名前にしたという前提で進めていきます。
Argo CD から read する必要があるので、リポジトリのスコープは public にしておいてください。

## ソースコードをコピー

以下のディレクトリに簡単な HTTP サーバーのソースコードと Kubernetes マニフェストが入っています。これを今作ったリポジトリにコピーしてください。

https://github.com/cybozu/argocd-handson/blob/main/step1/

コピーしたファイルやディレクトリをすべをコミットして `git push` してください。

## イメージをビルド

`make push` するとイメージをビルドしてローカルの kind クラスタにイメージをロードできます。やってみてください。ただし、mac を使っている人は `go build` に環境変数として `GOOS=linux GOARCH=amd64` を渡す必要があるので注意してください。

本来は `make push` でリモートにあるコンテナレジストリにイメージを push すべきなのですが、今回のハンズオンではコンテナレジストリを用意する手間を省くためにイメージはローカルだけで完結するようにしています。

※ kind 以外のクラスタ構築ツールを使っている人は `Makefile` の push の手順を書き換える必要があります。例えば、minikube を使っている人は `kind load docker-image` の代わりに `minikube image load` を使うように書き換えてください。

## イメージの動作確認

念のため、今ビルドしたイメージが動くのか確かめてみましょう。
まずはサーバーを起動します。

```bash
docker run --rm -p 3000:8080 docker.example.com/hello-server:latest
```

そして別のシェルから以下を実行してください。

```bash
curl -i localhost:3000
```

正常にレスポンスが返ってくれば成功です。

※ ローカル側のポートを 3000 にしているのは、Argo CD 用のポートフォワードと被らないようにするためです。

## Kubernetes にデプロイ

Kubernetes クラスタにデプロイしてみましょう。
まずは Argo CD を使わず、普段通り `kubectl apply` でデプロイします。

```bash
kubectl create namespace hello-server
kubectl apply -n hello-server -f kubernetes/deployment.yaml
kubectl apply -n hello-server -f kubernetes/service.yaml

# 確認
kubectl get all -n hello-server

# アクセスしてみる
kubectl exec -it bastion -- curl -i http://hello-server.hello-server.svc.cluster.local
```

アクセスが正常に行われれば成功です。

## 後片付け

以上で Argo CD の使い方を学ぶ準備ができました。
次のステップで Argo CD を使ってデプロイしなおすので、一旦 Kubernetes 環境は綺麗にしておきます。

```bash
kubectl delete namespace hello-server
```
