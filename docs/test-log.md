# Rwikiテスト

- テストはLLMを活用するので、Rwiki-devディレクトリ内にVaultをインスタンス
- gitignoreに登録し、リポジトリから除外
- `.kiro/specs/rw-light-rename/manual-verification.md`を参照

## 1. セットアップ

### 新規 Vault 初期化

#### ターミナルで作業

~~~
# 1. 新規空ディレクトリを作成して初期化
cd /Users/Daily/Development/Rwiki-dev
mkdir tVault
python scripts/rw_cli.py init ./tVault
cd tVault

# 2. symlink の実態を確認
ls -l scripts/rw
ls
# 3. gitignoreへtVaultを登録
% cat .gitignore
__pycache__/
*.pyc
logs/
TODO_NEXT_SESSION.md
tVault/

# 4. このターミナルでrwコマンドの操作を行う
~~~

#### Obsidian設定：

- 保管庫としてフォルダを開くを選択し、`/Users/Daily/Development/Rwiki-dev/tVault/`を選択

- 「新規添付ファイルの作成場所」 >> `/Users/Daily/Development/Rwiki-dev/tVault/raw/incoming/assets/`

  - ObsidianのPreference > ファイルとリンク > 新規添付ファイルの作成場所

- 同様に「新規ノートを作成するフォルダ」>>` /Users/Daily/Development/Rwiki-dev/tVault/raw/incoming/meeting-notes`

- 除外ファイルに`AGENTS.bak/`を指定

  #### Web Clipper

- プラグイン導入：Dataview、Smart Composer, Obsidian Web Clipper（ブラウザ拡張）

  - 左下の歯車アイコン → **Settings**, 左メニュー **Community plugins** をクリック
  - 設定はブラウザのURL入力の左のObsedianマークから歯車マークをクリック
  - デフォルトテンプレートで、ノート名を`{{date|date:"YYYY-MM-DD"}}-{{title|safe_name}}`、ノートの場所を`raw/incoming/articles`

#### 別ターミナルでClaudeを起動

~~~
cd /Users/Daily/Development/Rwiki-dev/.tVault
claude
~~~

※このターミナルはRwiki実行用のclaudeターミナル。開発デバッグに使うclaudeターミナルとは違うので注意。



## 2. 三匹の子豚の文書から

文書を投入

`/Users/Daily/Development/Rwiki-dev/sample/fairy-tale/三匹の子豚.md`を`/Users/Daily/Development/Rwiki-dev/tVault/raw/incoming/articles/`に投入