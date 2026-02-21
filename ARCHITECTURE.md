# ActionController::OpenApi

ActionController::OpenApiを用いると、`app/views` 以下に定義したAPIスキーマを利用できます。

## 使い方（例）

jqまたはjbuilderのビューがあると仮定します。

```
/app
    /views
        /items
            _show.json.jbuilder <--- ふだんどおり
            _show.schema.json <--- 新要素！
```

隣に JSON または YAML でスキーマを書けます。paths（/items/{id}） や リクエストメソッド（get）はRailsのルーティングから推論可能なのでユーザーは書く必要はありません。

```json:_show.schema.json
{
    "summary": "Represents an item",
    "description": "This resource represents an individual item in the system. Each item is identified by a numeric `id`.",
    "parameters": [...],
    "responses": {
        "200": { ... }
    }
}
```

このファイルがある状態で、controllerで以下のように記述できます。

```ruby:items_controller.rb
class ItemsController < ApplicationController
    around_action :validate_by_openapi_schema!, if: -> { Rails.env.development? }, only: :show

    def show
        # ...
    end
end

class ApplicationController < ActionController::Base
    include ActionController::OpenApi::ControllerMethods
end
```

URLパラメータやリクエストボディがおかしい場合は bad_request を返し、レスポンスがスキーマにマッチしない場合は500を返します（いずれの場合も独自の例外をraiseするので、ユーザーランドでrescueすることも可能）

## ドキュメント生成

`.schema.json` をまとめて1つの OpenAPI ドキュメントを作ることができます。

### Mountable Engine

以下のようにルーティングにマウントすると、ランタイムで `.schema.json` を収集して Redoc をレンダリングします。主にdevelopment用です。

```ruby
mount ActionController::OpenApi::DocumentPage, at: "/admin/openapi"
```

### Rakeタスク

以下のタスクを実行すると、`.schema.json` を収集して Redoc をプリコンパイルします。静的にホストする用途です。

```
bin/rails action_controller_openapi:precompile
```
