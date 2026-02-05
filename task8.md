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
// Комбинированная стратегия: геозона + категория + хэш для равномерности
sh.shardCollection("mobile_world.products", {
  "geo_zone": 1,          // Первичное разделение по регионам
  "category": 1,          // Внутри региона - по категориям
  "distribution_hash": "hashed"  // Равномерное распределение внутри категории
});
```

#### Автоматическая настройка зон для популярных категорий
```
const configureZonedSharding = async () => {
  const HOT_CATEGORIES = ["Электроника", "Смартфоны", "Ноутбуки"];
  const REGIONS = ["msk", "spb", "ekb", "nsk", "vladivostok"];
  
  // 1. Создаем базовые географические зоны
  REGIONS.forEach(region => {
    const zoneTag = `zone_${region}`;
    
    sh.addTagRange(
      "mobile_world.products",
      { 
        geo_zone: region,
        category: MinKey,
        brand: MinKey,
        sku_hash: MinKey
      },
      { 
        geo_zone: region,
        category: MaxKey,
        brand: MaxKey,
        sku_hash: MaxKey
      },
      zoneTag
    );
    
    // Привязываем шарды к географическим зонам
    sh.addShardToZone(`shard_${region}_primary`, zoneTag);
    sh.addShardToZone(`shard_${region}_secondary`, zoneTag);
  });
```

## Мониторинг
- **Prometheus + Grafana** для визуализации метрик
- **Пороги алертов**: дисбаланс > 40%, нагрузка на шард > 50%
- **Автоматический ответ** при превышении порогов
