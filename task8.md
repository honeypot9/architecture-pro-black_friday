### <a name="_b7urdng99y53"></a>**Название задачи:**

ADR-8 Выявление и устранение «горячих» шардов

### <a name="_hjk0fkfyohdk"></a>**Автор:**

Denis Marunich

### <a name="_uanumrh8zrui"></a>**Дата:**

2025-02-01
# ADR-8: Мониторинг и балансировка шардов MongoDB

## Автор
Denis Marunich

## Дата
2025-02-01

## Статус
Принято
## Решение

### 1. Ключевые метрики мониторинга

#### А. Нагрузка по шардам
```
// Операции в реальном времени
db.serverStatus().opcounters;

// Медленные запросы
db.setProfilingLevel(1, 50);
```

#### Б. Распределение данных
```
// Объём данных по шардам
db.products.getShardDistribution();

// Статистика коллекций
db.products.stats();
```

#### В. Использование ресурсов
```
// Память и кэш
db.serverStatus().mem;
db.serverStatus().wiredTiger.cache;
```

### 2. Автоматическое перераспределение

#### А. Балансировка чанков
```
// Добавление шарда
sh.addShard("shard3/mongodb-shard3-1:27017");

// Разделение чанков
sh.splitAt("mobile_world.products", { 
  "category": "Электроника", 
  "distribution_hash": "a1b2c3" 
});

// Перемещение чанка
sh.moveChunk(
  "mobile_world.products",
  { "category": "Электроника" },
  "shard2"
);
```

#### Б. Скрипт автоматической балансировки
```
// auto_balancer.js
class ShardBalancer {
  async rebalanceIfNeeded() {
    const stats = db.products.stats();
    const chunks = Object.values(stats.shards).map(s => s.chunks);
    const avg = chunks.reduce((a, b) => a + b) / chunks.length;
    
    // Запуск балансировки при дисбалансе > 30%
    if (chunks.some(c => Math.abs(c - avg) / avg > 0.3)) {
      sh.startBalancer();
      sh.enableAutoSplit();
    }
  }
}
```

### 3. Стратегия шардирования

#### Составной ключ для равномерного распределения:
```
// Новая стратегия вместо шардирования только по category
sh.shardCollection("mobile_world.products", {
  "category": 1,
  "distribution_hash": "hashed"
});
```

## Мониторинг
- **Prometheus + Grafana** для визуализации метрик
- **Пороги алертов**: дисбаланс > 40%, нагрузка на шард > 50%
- **Автоматический ответ** при превышении порогов
