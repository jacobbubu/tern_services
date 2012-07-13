Media Service:

Upload:
  根据Access Token，获得用户身份。
  检查:
    User_ID和Mid的前半部分是一致的。

  PUT: 
    
    md5: 用于final confirm, 如果没有，则不选
    Content-Length: 20480  (当前包的尺寸)
    Content-MD5: 截止到目前的md5值。
    Content-Range: bytes 0-20479/1234567
    Content-Type: mime

    Service收到put后，保存到临时文件。mid.tmp
    chunck大小为256K，缺省值。

    创建文件时，需要添加ensureIndex fileName的索引，以便于查找。

    最后一个包成功后，计算md5。
    成功:
      将临时文件名改为正常文件名。
    失败:
      清除既有的上传成果，返回308，RANGE: 0-0。

    问题：
    1. 如果想重新上传? 用del method吧。
    2. 上传后还有哪些操作?

  GET:
    如果文件存在，则返回。
    否则404或401，看权限。
