1. Запускаем приложение и шарды MongoDb:
```shell
docker compose up -d
```
2. Инициализируем сервис конфигурации:
```shell
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF
```
3. Инициализируем кластер shard1:
```shell
docker compose exec -T shard1_1 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1_1:27018" },
        { _id : 1, host : "shard1_2:27018" },
        { _id : 2, host : "shard1_3:27018" }       
      ]
    }
);
EOF
```
4. Инициализируем кластер shard2:
```shell
docker compose exec -T shard2_1 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2_1:27018" },
        { _id : 1, host : "shard2_2:27018" },
        { _id : 2, host : "shard2_3:27018" }       
      ]
    }
);
EOF
```
5. Инициализируем роутер и наполняем его тестовыми данными:
```shell
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1_1:27018,shard1_2:27018,shard1_3:27018");
sh.addShard( "shard2/shard2_1:27018,shard2_2:27018,shard2_3:27018");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF
```
6. Проверяем количество документов в базе и количество реплик (**приложение доработано, чтобы дополнительно возвращать количество документов и реплик на каждой шарде**):
```shell
curl  http://localhost:8080 |jq
```

7. Проверяем работу кэширования запустив запрос получения документов с измерением времени выполнения 2 раза подряд
```shell
curl -o /dev/null -s -w "Time total: %{time_total}s\n" http://localhost:8080/helloDoc/users
```