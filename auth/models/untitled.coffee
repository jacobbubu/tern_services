#Juma创建Memo
memo = 
  ts: 1338863881596
  mid: 'juma:1001'
  created_by: 'juma'                #created_by和mid中的用户不一定完全一样
  create_at : '20120301T12:22:09Z'  #创建发生在Juma Rec. Client上的时间戳
  created_on: '3FdRwwp09A'
  media_meta: {}
  geo: {}

# Juma在另外一台设备修改了Memo的geo信息
memo = 
  ts: 1338863910489           #更新提交到Rec. Service时候的时间戳
  mid: 'juma:1001'
  created_by: 'juma'          # created_by和mid中的用户不一定完全一样
  create_at : '20120301T12:22:09Z'
  created_on: '3FdRwwp09A'
  media_meta: {}
  geo: {}
  update_by : 'juma'
  update_at : '20120301T12:23:19Z'  # 更新发生在Juma Rec. Client上的时间戳
  update_on : '6FpwDf7078'          # Juma在另外一台设备修改

# Juma分享给Nancy
#Juma的roster:
roster = 
  owner_ts: 1338865411732
  users: ['nancy']

#Nancy看到的memo是:
memo = 
  ts: 1338863910489
  mid: 'juma:1001'
  created_by: 'juma'
  create_at : '20120301T12:22:09Z'
  created_on: '3FdRwwp09A'
  media_meta: {}
  geo: {}
  update_by : 'juma'
  update_at : '20120301T12:23:19Z'
  update_on : '6FpwDf7078'

#Nancy修改了该memo
memo = 
  ts: 1338863910489   # Nancy入库的时间戳。我们希望不同的Data Zone的服务器的时间同步，误差不会很大。
  mid: 'juma:1001'
  created_by: 'juma'
  create_at : '20120301T12:22:09Z'
  created_on: '3FdRwwp09A'
  media_meta: {}
  geo: {}             #new data here
  update_by : 'nancy'
  update_at : '20120302T02:13:59Z'
  update_on : '707Su^teWq'

#Juma在Nancy修改之前也修改了该memo，但是尚未同步给Nancy。
memo = 
  ts: 1338863910370
  mid: 'juma:1001'
  created_by: 'juma'
  create_at : '20120301T12:22:09Z'
  created_on: '3FdRwwp09A'
  media_meta: {}
  geo: {}             #new data here
  update_by : 'juma'
  update_at : '20120302T02:13:57Z'
  update_on : '6FpwDf7078'

#Juma所在DataZone收到了Nancy所提交的变更，但是由于Nancy的owner_ts的数值小于本地的owner_ts，因此Nancy的提交数据被打回，同时带着最新的memo数据。
#如果最新的memo数据在这个返回之前已经被同步，那么这个数据就丢弃，否则就入库。
#入库的含义就是记录memo folder以及相关的change_log folder。

#分享的Memo，其自动Tag都不打。