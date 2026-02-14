# サブスクリプション管理システムの実装

動画配信サービスにおける定期購読の開始・更新・解約を管理する API を Ruby on Rails で実装してください

実務に耐えうる設計・実装（拡張性・分析可能性・冪等性・スケーラビリティ等）を意識し、README に設計の概要や工夫したポイントを記載してください（日本語もしくは英語）

不明点は適切に定義して構いません

- ユーザは Apple のアプリ内課金でサブスクリプションを購入する
- 決済完了後、アプリ側から Rails API に決済情報を送信し、サブスクリプションを仮開始する
- その後、Apple からの Webhook 通知（開始・更新・解約）を受信して、サブスクリプションの状態を更新する。署名検証は省略して良い
- 解約時でも現在の有効期限までは利用可能とする

評価の観点：要件定義力・設計力・拡張性・説明力

## クライアント -> サーバ (決済完了直後)

```json
{
  "user_id": "string",
  "transaction_id": "string",
  "product_id": "string"
}
```

- user_id: 本来は Cookie 等から取得する値だが、今回わかりやすくするためパラメータとして渡す形にする。検証不要
- transaction_id: サブスクリプションを一意に識別する ID。同じサブスクリプションなら自動更新されても同じ値
- product_id: サブスクリプションプランの ID。例：com.samansa.subscription.monthly

この時点では仮開始。Apple Webhook 到着で本開始。仮開始中は視聴不可。

## Apple -> サーバ （Webhook）

```json
{
  "notification_uuid": "string",
  "type": "PURCHASE" "RENEW" "CANCEL",
  "transaction_id": "string",
  "product_id": "string",
  "amount": "3.9",
  "currency": "USD",
  "purchase_date": "2025-10-01T12:00:00Z",
  "expires_date": "2025-11-01T12:00:00Z",
}
```

- notification_uuid: 通知ごとに一意の値
- type: 通知の種類。PURCHASE は新規購入、RENEW は自動更新、CANCEL は解約
- transaction_id: サブスクリプションを一意に識別する ID。同じサブスクリプションなら自動更新されても同じ値
- product_id: サブスクリプションプランの ID。例：com.samansa.subscription.monthly
- amount / currency: 課金金額と通貨
- purchase_date: 現在のサブスクリプション期間の開始日時
- expires_date: 次回更新またはサブスクリプション終了日時
