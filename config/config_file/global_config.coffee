module.exports = 
  centralAuth:
    websocket:
      bind:
        host: '*'
        port: 22000
        protocol: 'ws'
      connect:
        host: 'localhost'
        port: 22000
        protocol: 'ws'
    zmq:
      router:
        bind:
          protocol: 'tcp'
          host: '*'
          port: 22100
        connect:
          protocol: 'tcp'
          host: '127.0.0.1'
          port: 22100
      dealer:          
        bind:
          protocol: 'ipc'
          host: '/tmp/tern.auth-dealer'
        connect:
          protocol: 'ipc'
          host: '/tmp/tern.auth-dealer'
  dataZones:
    beijing:
      websocket:
        bind:
          host: '*'
          port: 23000
          protocol: 'ws'
        connect:
          host: 'localhost'
          port: 23000
          protocol: 'ws'
      media:
        bind:
          host: '*'
          port: 23100
        connect:
          host: 'localhost'
          port: 23100
          protocol: 'http'
      dataQueuesToOtherZones:
        beijing:
          router:
            bind:
              host: '*'
              port: 23200
            connect:
              host: '127.0.0.1'
              port: 23200
          dealer:
            bind:
              host: '*'
              port: 23201
            connect:
              host: '127.0.0.1'
              port: 23201
        tokyo:
          router:
            bind:
              host: '*'
              port: 23202
            connect:
              host: '127.0.0.1'
              port: 23202
          dealer:
            bind:
              host: '*'
              port: 23203
            connect:
              host: '127.0.0.1'
              port: 23203
        singapore:
          router:
            bind:
              host: '*'
              port: 23204
            connect:
              host: '127.0.0.1'
              port: 23204
          dealer:
            bind:
              host: '*'
              port: 23205
            connect:
              host: '127.0.0.1'
              port: 23205
        virginia:
          router:
            bind:
              host: '*'
              port: 23206
            connect:
              host: '127.0.0.1'
              port: 23206
          dealer:
            bind:
              host: '*'
              port: 23207
            connect:
              host: '127.0.0.1'
              port: 23207
        ireland:
          router:
            bind:
              host: '*'
              port: 23208
            connect:
              host: '127.0.0.1'
              port: 23208
          dealer:
            bind:
              host: '*'
              port: 23209
            connect:
              host: '127.0.0.1'
              port: 23209
        sao_paulo:
          router:
            bind:
              host: '*'
              port: 23210
            connect:
              host: '127.0.0.1'
              port: 23210
          dealer:
            bind:
              host: '*'
              port: 23211
            connect:
              host: '127.0.0.1'
              port: 23211
      mediaQueuesToOtherZones:
        beijing:
          router:
            bind:
              host: '*'
              port: 23250
            connect:
              host: '127.0.0.1'
              port: 23250
          dealer:
            bind:
              host: '*'
              port: 23251
            connect:
              host: '127.0.0.1'
              port: 23251
        tokyo:
          router:
            bind:
              host: '*'
              port: 23252
            connect:
              host: '127.0.0.1'
              port: 23252
          dealer:
            bind:
              host: '*'
              port: 23253
            connect:
              host: '127.0.0.1'
              port: 23253
        singapore:
          router:
            bind:
              host: '*'
              port: 23254
            connect:
              host: '127.0.0.1'
              port: 23254
          dealer:
            bind:
              host: '*'
              port: 23255
            connect:
              host: '127.0.0.1'
              port: 23255
        virginia:
          router:
            bind:
              host: '*'
              port: 23256
            connect:
              host: '127.0.0.1'
              port: 23256
          dealer:
            bind:
              host: '*'
              port: 23257
            connect:
              host: '127.0.0.1'
              port: 23257
        ireland:
          router:
            bind:
              host: '*'
              port: 23258
            connect:
              host: '127.0.0.1'
              port: 23258
          dealer:
            bind:
              host: '*'
              port: 23259
            connect:
              host: '127.0.0.1'
              port: 23259
        sao_paulo:
          router:
            bind:
              host: '*'
              port: 23260
            connect:
              host: '127.0.0.1'
              port: 23260
          dealer:
            bind:
              host: '*'
              port: 23261
            connect:
              host: '127.0.0.1'
              port: 23261