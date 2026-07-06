# xium-kratos Kubernetes マニフェスト

このディレクトリには、xium-kratos のスキーマランタイムを別プロジェクト向けに作成するための Kubernetes マニフェストテンプレートを配置します。

IAM チームは、このディレクトリを利用チーム向けの配布用フォルダとして複製し、ヒアリング結果をもとに作成した identity schema を含めて渡します。

このディレクトリ自体はデプロイ対象ではありません。

スキーマランタイムは共通 image を利用します。利用チームは、コピー後の別プロジェクトフォルダで各種ダミー設定値を実際の値へ置き換えてください。

## CICD 連携

CICD で指定するファイルは、コピー先で別プロジェクト向けに修正した `xium-kratos-schema-runtime.yaml` です。

```text
xium-kratos-schema-runtime.yaml
```

このファイルは、AegisInjection、ConfigMap、migration Job、Deployment、Service を 1 ファイルにまとめた CICD 向け manifest です。

運用の流れは次の通りです。

1. `04_IAM/04_APPS/ory-kratos/.docker/k8s` を別プロジェクトフォルダへコピーする。
2. コピー先で、`xium-kratos-schema-runtime.yaml` の schema runtime 名、schema、Kratos 設定、OpenBao 参照先、resource などを別プロジェクト向けに修正する。
3. コピー先の `xium-kratos-schema-runtime.yaml` を `01_Xium/01_構築/04_CICD` の app registration workflow に渡してデプロイする。

CICD の manifest import が raw resource として取り込めるように、各 resource には次の label を付与します。

```yaml
xium.io/project-component: "true"
```

Argo CD の同期順序は `argocd.argoproj.io/sync-wave` で指定します。

- `-30`: AegisInjection
- `-20`: ConfigMap
- `-10`: Service
- `-5`: migration Job
- `0`: Deployment

## 命名

- スキーマランタイム名: `example-schema`
- 共通 image: `xiumjp/xium-karats:dev`
- Deployment 名: `example-schema-xium-kratos`
- Public Service 名: `example-schema-xium-kratos-public`
- Admin Service 名: `example-schema-xium-kratos-admin`

スキーマランタイム名は、Kubernetes resource 名や label の基準名として扱います。

実際の Pod 名には Kubernetes が suffix を付与するため、スキーマランタイム名そのものとは一致しません。

## ランタイム切り替え

共通 image は、mount されたファイルと環境変数を使ってスキーマランタイムの動作を切り替えます。

- `XIUM_KRATOS_SCHEMA_RUNTIME_NAME`: スキーマランタイム名
- `XIUM_KRATOS_SCHEMA_ID`: Kratos schema ID
- `XIUM_KRATOS_SCHEMA_PATH`: mount された schema JSON のパス
- `XIUM_KRATOS_PUBLIC_BASE_URL`: Public API の base URL
- `XIUM_KRATOS_ADMIN_BASE_URL`: Admin API の base URL

schema JSON 全体は ConfigMap から mount します。

schema JSON そのものを環境変数として渡さないでください。

## Secret 注入

秘匿値は、AegisInjection により OpenBao から対象 Pod へ環境変数として注入します。

ランタイムの秘匿値を Kubernetes Secret manifest に保存しないでください。

`security` namespace は事前に作成されている前提です。

`security` namespace には、次の label が付与されている必要があります。

```yaml
aegis.scm.xium.io/enabled: "true"
```

対象 Pod template には、次の label と annotation が必要です。

```yaml
labels:
  aegis.scm.xium.io/injection: "enabled"
annotations:
  kms.xium.io/injection: preinjection
```

OpenBao のダミー secret path は `xium-kratos-schema-runtime.yaml` に定義しています。

注入される環境変数は次の通りです。

- `DSN`
- `COURIER_SMTP_CONNECTION_URI`
- `SECRETS_COOKIE_0`
- `SECRETS_CIPHER_0`

## 暫定運用

1. IAM チームが、クライアントから identity schema とスキーマランタイム名をヒアリングする。
2. IAM チームが、スキーマランタイム名の重複がないことを確認する。
3. IAM チームが、このディレクトリを別プロジェクトフォルダへコピーする。
4. IAM チームが、ヒアリング結果をもとに identity schema を作成し、コピー先の `xium-kratos-schema-runtime.yaml` に含める。
5. IAM チームが、配布用フォルダを利用チームへ渡す。
6. 利用チームが、配布用フォルダの manifest を自チームの環境、命名、OpenBao 参照先に合わせて修正する。
7. 利用チームが、必要な秘匿値を OpenBao に登録する。
8. 利用チームが、CICD の app registration workflow にコピー先の `xium-kratos-schema-runtime.yaml` を渡す。
9. CICD / Argo CD が、xium-kratos の各 resource をデプロイする。

IAM チームは、利用チームの環境へ直接デプロイしません。

## 利用チームの修正対象

- `xium-kratos-schema-runtime.yaml` の schema JSON
- スキーマランタイム名
- Kratos の Public / Admin base URL
- OpenBao の secret path
- resource requests / limits
- replica 数
- 環境に応じた DNS、hostname、network 設定

Kubernetes への反映は、`01_Xium/01_構築/04_CICD` の GitOps / Argo CD 経由で行います。
