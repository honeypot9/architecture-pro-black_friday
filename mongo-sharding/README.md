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
3. Инициализируем shard1:
```shell
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 1, host : "shard1:27018" }       
      ]
    }
);
EOF
```
4. Инициализируем shard2:
```shell
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 1, host : "shard2:27019" }       
      ]
    }
);
EOF
```
5. Инициализируем роутер и наполняем его тестовыми данными:
```shell
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF
```
6. Проверяем количество документов в базе (приложение доработано, чтобы дополнительно возвращать количество документов на каждой шарде):
```shell
curl  curl http://localhost:8080 |jq
```
