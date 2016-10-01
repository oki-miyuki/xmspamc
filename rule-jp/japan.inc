# Fromヘッダで日本語を使う人が当たり前にいるので必須
score FROM_EXCESS_BASE64 0
# 生JISヘッダを許容するのであれば以下を追加
score SUBJ_ILLEGAL_CHARS 0
# 今後、UTF-8の日本語メールが増えてくることを考慮する場合には以下を追加
score MIME_BASE64_TEXT 1.0
# 署名の整形のためにスペースを多用しているとTVD_SPACE_RATIOにマッチ
# するので、下記ルールを追加
score TVD_SPACE_RATIO 0
# ダブルクォーテーションの連続という事だが、日本語との相性悪し
score WEIRD_QUOTING 0
# 2.8 は、ちょっと高いのではなかろうか
score RATWARE_MS_HASH 1.2
# 日本語はスペースが入らないで誤判定されてしまう
score TVD_SPACE_RATIO_MINFP 0.0
