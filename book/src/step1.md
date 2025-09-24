# Step1: kubectl apply でデプロイする

まずは Argo CD を使わずに普通にサービスをデプロイしてみます。

## Git リポジトリを作る

GitHub に新しく Git リポジトリを作成してください。名前は何でもいいですが、ここでは `hello-server` という名前にしたという前提で進めていきます。リポジトリのスコープは public にしておいてください。

## ソースコードをコピー

以下のディレクトリに簡単な HTTP サーバーのソースコードと Kubernetes マニフェストが入っています。これを今作ったリポジトリにコピーしてください。

コピーしたらソースコード内に “YOUR_NAME” と書いてある場所があるので、これを自分の名前に書き換えてください。

```bash
❱ git grep YOUR_NAME
Makefile:CONTAINER_REPOSITORY = ghcr.io/YOUR_NAME/hello-server
kubernetes/deployment.yaml:        image: ghcr.io/YOUR_NAME/hello-server:latest
```

書き換えが終わったらコミットして `git push` しておいてください。

## イメージをビルド

`make push` するとイメージをビルドしてローカルの kind クラスタにイメージをロードできます。やってみてください。ただし、mac を使っている人は Go のビルド時に `GOOS=linux GOARCH=amd64` を指定する必要があるので注意してください。

※ kind 以外のクラスタ構築ツールを使っている人は `Makefile` の push の手順を書き換える必要があります。例えば、minikube を使っている人は `kind load docker-image` の代わりに `minikube image load` を使うように書き換えてください。

## イメージの動作確認

```bash
docker run --rm -p 3000:8080 ghcr.io/YOUR_NAME/hello-server:latest
```

別のシェルから

```bash
curl -i localhost:3000
```

※ ローカル側のポートを 3000 にしているのは、Argo CD 用のポートフォワードと被らないようにするためです。

## Kubernetes にデプロイ

```bash
kubectl create namespace hello-server
kubectl apply -n hello-server -f kubernetes/deployment.yaml
kubectl apply -n hello-server -f kubernetes/service.yaml

# 確認
kubectl get all -n hello-server

# アクセスしてみる
kubectl exec -it bastion -- curl -i http://hello-server.hello-server.svc.cluster.local
```

## 後片付け

次に Argo CD を使ってデプロイしなおすので、一旦 Kubernetes 環境は綺麗にしておきます。

```bash
kubectl delete namespace hello-server
```
