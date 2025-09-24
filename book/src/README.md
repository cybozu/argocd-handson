# 実践 Argo CD

## Introduction

Argo CD は Kubernetes へのデプロイを自動化するためのツールです。
Argo CD を使えば、手動で `kubectl apply` を行うことなくマニフェストを必要なときに自動的に apply し、リソースの状態を常にコードと同期した状態に保つことができます。
これにより、人手によるミスを減らし、Kubernetes での運用を安全かつ効率的に行うことができます。

実践 Argo CD は Argo CD を使って Web サービスを実際にデプロイしてみるハンズオンです。Kubernetes の初歩は知っているけど、Argo CD については何も知らない人を対象にしています。


このハンズオンは、最も単純な例からスタートして、アップデートや複数環境対応といったよくある要件を実装していきます。

このハンズオンを終えれば、Argo CD の基本的な利用方法を理解できるはずです。

## 目次

- [Step0: 環境準備](./step0.md)
- [Step1: kubectl apply でデプロイする](./step1.md)
- [Step2: Argo CD を使ってデプロイしてみる](./step2.md)
- [Step2.5: jsonnet 入門](./step2.5.md)
- [Step3: アップデートできるようにする](./step3.md)
- [Step4: 複数環境にデプロイする](./step4.md)
- [Step5: app-of-apps](./step5.md)
