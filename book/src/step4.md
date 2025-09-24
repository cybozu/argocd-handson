# Step4: 複数環境にデプロイする

実際の運用ではひとつのサービスを複数環境にデプロイする必要があります。典型的には、dev 環境、staging 環境、prod 環境の３つの環境にデプロイすることになるでしょう。このハンズオンでは、dev、staging、prod の３環境にデプロイする例を扱います。

GitOps では環境と Git ブランチを対応させます。このハンズオンでは以下のようにブランチを切ることにします。


| 環境 | ブランチ | 用途
| ---- | -------- | ----
| dev | develop | 開発、試験など
| staging | main | 適用前試験など
| prod | release | 運用

また、例をより現実に近づけるために、環境ごとに異なる設定をしなければならないという要件を追加します。具体的には、hello-server に渡す `MESSAGE` 環境変数を環境に合わせて以下のように設定することにします。

| 環境 | `MESSAGE`
| ---- | -----------
| dev | `Hello (dev)`
| staging | `Hello (staging)`
| prod | `Hello (prod)`

## Namespace を用意

このハンズオンでは、環境ごとに Namespace を用意することで仮想的に環境を切り分けることにします。

```bash
kubectl create namespace dev-hello-server
kubectl create namespace staging-hello-server
kubectl create namespace prod-hello-server
```

## MESSAGE を差し込めるようにする

`MESSAGE` を環境ごとに変えたいので、`MESSAGE` を TLA によって指定できるようにしましょう。Step3 のやり方を参考にやってみてください。

hello-server の kubernetes ディレクトリで以下を実行して `{ "name": "MESSAGE", "value": "Hello (dev)" }` が `env` の配列に追加されていれば成功です。

```bash
jsonnet --tla-str tag=abcdefg --tla-str message='Hello (dev)' main.jsonnet
```

成功したら一旦 `git commit` しておいてください。

## ブランチの作成

各環境に対応するブランチを hello-server リポジトリに用意しましょう。`main` (staging に対応) はすでにあるので、`develop` (dev に対応) ブランチと `release` (prod に対応) ブランチを作成してください。参照先は main と同じコミットで大丈夫です。

ブランチを作成したら、各ブランチを GitHub に push し、さらに各ブランチで `make push` を行ってください。

## Application リソースの jsonnet 化

それでは hello-apps リポジトリに移動して、3環境の hello-server をデプロイしていきましょう。

デプロイ先の環境が３つになったので、Application リソースも３つ作る必要があります。当然ですが、共通部分はくくりだしたいので、パラメタライズできるように Application リソースを jsonnet 化します。 

Step3 の手順を参考に、hello-apps の hello-server.yaml を jsonnet 化して、hello-server.libsonnet を作ってください。

そして、hello-server.libsonnet の内容を関数でくるみ、`env` と `branch` を引数で渡せるようにしましょう。
そして、与えられた `env` と `branch` に応じて、以下のフィールドが正しく設定されるようにコードを修正していきましょう。

- `metadata.name`
    - 値に `env + '-hello-server'` を渡すようにする。
- `spec.source.targetRevision`
    - 値に `branch` を渡すようにする。
- `spec.source.directory.jsonnet.tlas`
    - 配列に `{name: 'message', value: 'Hello (%s)' % env}` を追加する。
- `spec.destination.namespace`
    - 値に `env + '-hello-server'` を渡すようにする。

最後に、環境ごとに main.jsonnet を作ります。hello-server.libsonnet と同じディレクトリに `dev`, `staging`, `prod` というディレクトリを作成し、それらの下に main.jsonnet を作成してください。例えば、`prod/main.jsonnet` は以下のような内容になります。

```jsonnet
(import '../hello-server.libsonnet')('prod', 'release')
```

> **Note:**
> 最終的なコードは以下のような構成になります。ここまでの説明でよくわからないところがあれば、以下のコードを参考にしてください。
>
> <https://github.com/cybozu/argocd-handson/tree/main/src/step4/>

`main.jsonnet` を作成できたら適用してみましょう。

```bash
jsonnet dev/main.jsonnet | argocd app create --upsert -f -
jsonnet staging/main.jsonnet | argocd app create --upsert -f -
jsonnet prod/main.jsonnet | argocd app create --upsert -f -
```

## 動作確認

適用できたかどうか確かめましょう。まずは Argo CD の UI を見に行き、エラーが出ていないかチェックしてください。

大丈夫そうなら bastion に入って curl でリクエストを送ってみましょう。

```bash
kubectl exec -it bastion -- bash
(bastion)$ curl -i hello-server.dev-hello-server.svc.cluster.local
...
Hello (dev) (v2.0.0)

(bastion)$ curl -i hello-server.staging-hello-server.svc.cluster.local
...
Hello (staging) (v2.0.0)

(bastion)$ curl -i hello-server.prod-hello-server.svc.cluster.local
...
Hello (prod) (v2.0.0)
```

環境によってメッセージが変化していることが確認できました。

次にアップデートを試してみましょう。

hello-server の develop ブランチに移動し、main.go の `version` を `v3.0.0` などに書き換えて commit & push してください。

そして `make push` し、`argocd app sync dev-hello-server` してください。(繰り返しますが、この手順は本来は CI で自動化されているものです。今回はハンズオンのため、手動でやっています)

すると dev 環境に `v3.0.0` がデプロイされるはずです。bastion から確認してみてください。

dev で動作確認できたら staging にデプロイしましょう。GitHub の UI に移動し、develop ブランチから main ブランチにプルリクエストを作り、マージしましょう。そして `main` ブランチで `git pull && make push && argocd app sync staging-hello-server` しましょう。これで staging にデプロイができます。

prod へのリリースも同様の手順です。やってみましょう。

動作確認が完了したらこのステップは完了です。hello-apps で変更したファイルをコミット & push して、次のステップに進みましょう。
