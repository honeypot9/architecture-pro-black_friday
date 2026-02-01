#!/bin/bash

sleep 2

docker compose exec -T configSrv mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
EOF

sleep 2

docker compose exec -T shard1-main mongosh --port 27018 <<EOF

 rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1-main:27018" },
        { _id : 1, host : "shard1-replica1:27040" },
        { _id : 2, host : "shard1-replica2:27041" }
      ]
    }
);
exit();
EOF

sleep 2

docker compose exec -T shard2-main mongosh --port 27019 <<EOF

rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2-main:27019" },
        { _id : 1, host : "shard2-replica1:27030" },
        { _id : 2, host : "shard2-replica2:27031" },
      ]
    }
  );
exit();
EOF


sleep 2


docker compose exec -T mongos_router mongosh --port 27020 <<EOF
use somedb

sh.addShard( "shard1/shard1-main:27018");
sh.addShard( "shard2/shard2-main:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
exit()
EOF

