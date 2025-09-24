# Step1: kubectl apply でデプロイする

まずは Argo CD を使わずに普通にサービスをデプロイしてみます。

## Git リポジトリを作る

GitHub に新しく Git リポジトリを作成してください。名前は何でもいいですが、ここでは `hello-server` という名前にしたという前提で進めていきます。
後々 Argo CD から read する必要があるので、リポジトリのスコープは public にしておいてください。

## ソースコードをコピー

`hello-server` に最初のコードを投入しましょう。

以下のディレクトリに簡単な HTTP サーバーのソースコードと Kubernetes マニフェストが入っています。

<https://github.com/cybozu/argocd-handson/tree/main/src/step1/>

これを今作ったリポジトリにコピーします。
カレントディレクトリが `hello-server` のトップにある状態で以下の手順を実行してください。

```bash
# 一時ディレクトリ作成してそこに移動
pushd $(mktemp -d)
# ソースコードを取得
git clone https://github.com/cybozu/argocd-handson .
# step1 の内容を元のディレクトリにコピー
cp -a src/step1/. $(dirs -l +1)
# 元のディレクトリに戻る
popd
```

コピーしたファイルやディレクトリをすべてコミットして `git push` しておいてください。

## イメージをビルド

`make push` するとイメージをビルドしてローカルの kind クラスタにイメージをロードできます。やってみてください。

※ mac を使っている人は `go build` に環境変数として `GOOS=linux GOARCH=amd64` を渡す必要があります。

※ kind 以外のクラスタ構築ツールを使っている人は `Makefile` の push の手順を書き換える必要があります。例えば、minikube を使っている人は `kind load docker-image` の代わりに `minikube image load` を使うように書き換えてください。

実際の運用では `make push` でコンテナレジストリへの push を行う想定ですが、今回のハンズオンではコンテナレジストリを用意する手間を省くために、コンテナレジストリへの push は行っていません。
その代わりに kind の機能を使ってノードに直接イメージをロードしています。

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
