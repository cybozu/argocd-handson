# Step3: アップデートできるようにする

現在のマニフェストは image に latest タグを指定しています。しかし、実際の運用では latest タグを使うことは非推奨です。第一に、latest タグの内容はその時々によって変化するので、デプロイに再現性がありません。第二に、ソースコードを更新したときにマニフェストに差分が発生しないので、差分発生をトリガーとしてデプロイを行う Kubernetes の考え方と相性が悪いです。

そこで、latest タグではなく、特定のバージョンを一意に指定できる文字列、例えばコミットハッシュを指定することにします。

しかし、ナイーブにこれを実現しようとすると、ソースコードに変更が入るたびにマニフェストの image を手動で変更することになります。実際にこういう運用をしているチームもあるのですが、煩雑ですしミスをするリスクもあるので自動化すべきでしょう。

よって、以下のような仕様にします。

- ソースコードが変更されるたびに、CI で docker イメージをビルドし、コミットハッシュをタグとして push する。
- Argo CD によって main ブランチを監視し、main ブランチが変更されるたびに main ブランチの最新のコミットハッシュを使ってサービスをデプロイする。

ただし、今回のハンズオンでは CI をセットアップする時間がないので人力 CI で代替します。

## jsonnet を導入する

今までマニフェストは単なる YAML ファイルでしたが、image タグを動的に差し込む必要があるので、何かしらの仕組みを導入しなければなりません。選択肢として

- kustomize
- jsonnet
- helm

などがありますが、このハンズオンでは jsonnet を採用します。

まず、既存のマニフェストを jsonnet 化していきましょう。

YAML から JSON に変換するスクリプトを書いておくと便利なので、以下のスクリプトを PATH の通ったディレクトリに `yaml2json` という名前で保存しましょう。 `chmod +x` もしておいてください。

```python
#!/usr/bin/env python3
import yaml, json, sys
docs = yaml.safe_load_all(sys.stdin)
jsons = [json.dumps(doc, indent=2) for doc in docs]
print("\n---\n".join(jsons))
```

(このスクリプトを動かすには PyYAML が必要です。入ってない人は `sudo apt install python3-yaml` または `python3 -m pip install pyyaml` でインストールしてください)

それでは、step2 で作成した YAML マニフェストを jsonnet 化していきましょう。
hello-server の `kubernetes` ディレクトリに移動して以下の手順を行ってください。

```bash
cat deployment.yaml | yaml2json | jsonnetfmt - > deployment.libsonnet
cat service.yaml | yaml2json | jsonnetfmt - > service.libsonnet
```

そして、`main.jsonnet` を以下の内容で作成します。

```jsonnet
[
  import 'deployment.libsonnet',
  import 'service.libsonnet',
]
```

これで jsonnet 化は完了です。動作確認してみましょう。

```bash
jsonnet main.jsonnet
```

これで2つのマニフェストを配列としてまとめたものが出力されれば成功です。

ここで jsonnet スクリプトの拡張子について説明しておきます。慣習的に以下のように拡張子を使い分けることが多いです。

- `.jsonnet`: エントリポイントとなる jsonnet スクリプト
- `.libsonnet`: 他の jsonnet スクリプトから import される jsonnet スクリプト

jsonnet 化ができたら `*.yaml` の方のマニフェストは不要なので `git rm` しておいてください（残していると Argo CD によって両方デプロイされてしまいます）。

## タグを差し込めるようにする

では、タグを外部から差し込めるようにしましょう。

まず、Deployment をタグを引数を取る関数として定義します。deployment.libsonnet を以下のように書き換えてください。

1. ファイルの先頭に `function(tag)` という行を挿入します。jsonnet では `function(引数) 式` という構文で無名関数を記述できます。もともと `deployment.libsonnet` はひとつの式だったので、これにより `tag` を受け取ってオブジェクトを返す関数になりました。

1. `image:` で始まる行を以下のように書き換えます。
    ```jsonnet
    image: 'docker.example.com/hello-server:' + tag,
    ```
    これで image のタグを外部から指定できるようになりました。

1. フォーマットを整えます。
   ```bash
   jsonnetfmt -i deployment.libsonnet
   ```

この修正によって deployment.libsonnet が関数化されたので、main.jsonnet の方も修正しなければなりません。以下のように、deployment.libsonnet に引数を渡すように書き換えます。

```jsonnet
function(tag)
  [
    (import 'deployment.libsonnet')(tag),
    import 'service.libsonnet',
  ]
```

この書き換えにより、main.jsonnet のトップレベルの式が関数を返すようになりました。この関数の引数は **TLAs (Top-Level Arguments)** と呼ばれます。TLAs の値は `jsonnet` コマンドのコマンドライン引数として与えることができます。

```bash
jsonnet --tla-str tag=abcdefg main.jsonnet
```

hello-server を変更したので、`git commit` と `git push` を行い、そして `make push` しておいてください。
`make push` は本来は CI で行うべきですが、今回のハンズオンでは人力で CI を代替します。

## Argo CD から TLAs 経由で引数を渡す

最後に、Argo CD から TLAs 経由でタグを差し込むようにしましょう。`hello-apps` の `hello-server.yaml` を以下のように書き換えてください。

```yaml
...
  source:
    ...
    path: step3/hello-server/kubernetes
    # ！！以下を追加！！
    # jsonnet の TLAs に渡す引数を指定する。
    directory:
      jsonnet:
        tlas:
        - name: "tag"
          value: "$ARGOCD_APP_REVISION"
    # ！！追加ここまで！！
...
```

`$ARGOCD_APP_REVISION` は [Build Envrionemnt](https://argo-cd.readthedocs.io/en/stable/user-guide/build-environment/) と呼ばれる環境変数的なもので、Argo CD が実行時にデプロイ対象のコミットハッシュに置き換えてくれます。このように指定することで、tag には hello-server の main ブランチの最新のコミットハッシュが 渡されます。

それでは、Application を更新しましょう。

```bash
argocd app create --upsert -f hello-server.yaml
```

このコマンドを打ったら Argo CD の UI を確認しましょう。うまく行っていれば、latest タグではなくコミットハッシュで指定されたイメージがデプロイされるはずです。

## サービスをアップデートしてみる

hello-server の main.go の version を `2.0.0` に書き換えてデプロイしてみましょう。

ソースコードを書き換える → コミット → git push します。

本来はこれだけで変更がデプロイされるはずですが、前述の通りハンズオンでは CI がないので以下の手順を行います。

```bash
# イメージをビルドして push する
make push

# Argo CD の sync を手動でキックする
# 何もしなくても待っていれば自動的に sync されるが、待つのが面倒なので
argocd app sync hello-server
```

sync が終われば、hello-server にリクエストを送ると `Hello (2.0.0)` が返ってくるはずです。
