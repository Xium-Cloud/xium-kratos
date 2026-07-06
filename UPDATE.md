# OryKratosバージョンアップ対応

## ざっくり流れ
1. xium-kratos の作業ツリーがきれいか確認する。
2. upstream がなければ登録する。
3. Ory の tag を fetch する。
4. Xium の main から更新用ブランチを作る。
5. 公式リリースタグを merge する。
6. 競合を解消する。
7. build/test/IDium 結合検証を行う。
8. 問題なければ main に取り込む。

```bash
git status -s 
git fetch upstream --tags

git switch main
git pull --ff-only origin main
git switch -c update/ory-kratos-v26.2.0

git merge --no-ff v26.2.0
```