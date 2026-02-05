### <a name="_b7urdng99y53"></a>**Название задачи:**

ADR-7 Проектирование схем коллекций для шардирования данных

### <a name="_hjk0fkfyohdk"></a>**Автор:**

Denis Marunich

### <a name="_uanumrh8zrui"></a>**Дата:**

2025-02-01

## Collections

### Orders

```json lines
{
  "_id": ObjectId,
  "user_id": ObjectId,
  "created_at": Date,
  "items": [
    {
      "product_id": ObjectId,
      "price": Number
    }
  ],
  "status": String,
  "total_price": Number,
  "geo": String
}
```

#### Шардирование

Shard key: geo

Стратегия: Range-based sharding по географии

geo изолирует заказы по регионам, ближе к пользователям. Эффективные запросы по зонам

### Products

```json lines
{
  "_id": ObjectId,
  "name": String,
  "category": String,
  "price": Number,
  "remaining_count": Number,
  "params": {
    "color": String,
    "size": String,
  }
}
```

#### Шардирование

Shard key: category

Стратегия: Range-based sharding

category обеспечивает логическое разделение данных. Поддерживает эффективные запросы по категориям

### Carts

```json lines
{
  "_id": ObjectId,
  "user_id": String,
  "session_id": String,
  "items": [
    {
      "product_id": ObjectId,
      "quantity": Number
    }
  ],
  "status": String,
  "created_at": Date,
  "updated_at": Date,
  "expires_at": Date
}
```

#### Шардирование

Shard key: user_id

Стратегия: Hash-based sharding

Равномерное распределение пользовательских данных. Изоляция корзин пользователей

## Команды настройки MongoDB

// Включение шардирования для базы данных

sh.enableSharding("mobile_world");

// Шардирование коллекции orders по geo (range-based)

sh.shardCollection("mobile_world.orders", { "geo": 1 });

// Шардирование коллекции products по category (range-based)  

sh.shardCollection("mobile_world.products", { "category": 1 });

// Шардирование коллекции carts по user_id (hash-based)

sh.shardCollection("mobile_world.carts", { "user_id": "hashed" });
