// Date : June 16 2012
// Converted by Pantelis Kalogiros to support binary data

// previous info
/**
* LZF - LZF compression implementation for JavaScript
*
* Provides LZF compression/decompression of strings
* Compatible with lzf_compress & lzf_decompress PHP functions (see LZF in PECL)
* Based on C source of LZF functions by Marc Alexander Lehmann (schmorp@schmorp.de)
* Based on C source of LZF PHP extension by Marcin Gibula (mg@iceni.pl)
*
* @class Provides methods for LZF compression/decompression
* @author  Alexey A.Znaev (znaeff@mail.ru) (http://xbsoft.org)
* @copyright   Copyright (C) 2011-2012 Alexey A.Znaev
* @license   http://www.gnu.org/licenses GNU Public License version 3
* @version   1.0
*/

 
// class constants
var _HLOG = 16,
  _HSIZE = ( 1 << ( _HLOG ) ),
  _MAX_LIT = ( 1 <<  5 ),
  _MAX_OFF = ( 1 << 13 ),
  _MAX_REF = ( ( 1 << 8 ) + ( 1 << 3 ) ),

// private methods
_FRST = function( p, sD ) {
    return( ( ( sD[ p ] ) << 8 ) | sD[ p + 1 ] );
  },
_NEXT = function( v, p, sD ) {
    return( ( v << 8 ) | sD[ p + 2 ] );
  },
_IDX = function( h ) {
    return( ( ( h >> ( 3 * 8 - _HLOG ) ) - h ) & ( _HSIZE - 1 ) );
  };

//
// Main Object
//
module.exports = {
  /**
  * @return String the decompressed data
  *
  * @param  Buffer compressed arraybuffer
  **/
  decompress : function lzfDecode( data ) {    
    var 
      size = data.readUInt32LE(0),
      sC = data.slice(4),
      //sC = data,
      clock = 0;

    var ip = 0, iEnd = sC.length,
    aRes,
    ctrl, len, ref;
    
    aRes = new Array(size)
    //aRes = []
    
    do {
      ctrl = sC[ ip++ ];
      if(ctrl < (1 << 5))
      {
        ++ctrl;
        if( ip + ctrl > iEnd ) throw new Error( "LZF JS ERROR 1 ");
        switch (ctrl)
        {
          case 32: aRes[ clock++ ] =(sC[(ip++)]); case 31: aRes[ clock++ ] =(sC[(ip++)]); case 30: aRes[ clock++ ] =(sC[(ip++)]); case 29: aRes[ clock++ ] =(sC[(ip++)]);
          case 28: aRes[ clock++ ] =(sC[(ip++)]); case 27: aRes[ clock++ ] =(sC[(ip++)]); case 26: aRes[ clock++ ] =(sC[(ip++)]); case 25: aRes[ clock++ ] =(sC[(ip++)]);
          case 24: aRes[ clock++ ] =(sC[(ip++)]); case 23: aRes[ clock++ ] =(sC[(ip++)]); case 22: aRes[ clock++ ] =(sC[(ip++)]); case 21: aRes[ clock++ ] =(sC[(ip++)]);
          case 20: aRes[ clock++ ] =(sC[(ip++)]); case 19: aRes[ clock++ ] =(sC[(ip++)]); case 18: aRes[ clock++ ] =(sC[(ip++)]); case 17: aRes[ clock++ ] =(sC[(ip++)]);
          case 16: aRes[ clock++ ] =(sC[(ip++)]); case 15: aRes[ clock++ ] =(sC[(ip++)]); case 14: aRes[ clock++ ] =(sC[(ip++)]); case 13: aRes[ clock++ ] =(sC[(ip++)]);
          case 12: aRes[ clock++ ] =(sC[(ip++)]); case 11: aRes[ clock++ ] =(sC[(ip++)]); case 10: aRes[ clock++ ] =(sC[(ip++)]); case  9: aRes[ clock++ ] =(sC[(ip++)]);
          case  8: aRes[ clock++ ] =(sC[(ip++)]); case  7: aRes[ clock++ ] =(sC[(ip++)]); case  6: aRes[ clock++ ] =(sC[(ip++)]); case  5: aRes[ clock++ ] =(sC[(ip++)]);
          case  4: aRes[ clock++ ] =(sC[(ip++)]); case  3: aRes[ clock++ ] =(sC[(ip++)]); case  2: aRes[ clock++ ] =(sC[(ip++)]); case  1: aRes[ clock++ ] =(sC[(ip++)]);
        }
      }
      else
      {
        len = ctrl >> 5;
        ref = clock - ((ctrl & 0x1f) << 8) - 1;
        if(ip > iEnd)  throw new Error( "LZF JS ERROR 2 ");
        if(len == 7){
          len += sC[(ip++)];
          if(ip > iEnd)  throw new Error( "LZF JS ERROR 3 ");
        }
        ref -= sC[(ip++)];
        if(ref < 0)  console.log( "LZF JS ERROR 4 ");
        if(ref >= clock)  throw new Error( "LZF JS ERROR 5 ");
      
        switch (len)
        {
          default:
          {
            len += 2;
            if (clock >= ref + len)
            {
            // Disjunct areas
            for( var jk = 0; jk < len; ++jk )
              aRes[ clock++ ] =( aRes[ ref + jk ] );
            }
            else
            {
            do
              aRes[ clock++ ] =(aRes[ref++]);
            while (--len);
            }

            break;
          }
          case 9: aRes[ clock++ ] =(aRes[ref++]);
          case 8: aRes[ clock++ ] =(aRes[ref++]);
          case 7: aRes[ clock++ ] =(aRes[ref++]);
          case 6: aRes[ clock++ ] =(aRes[ref++]);
          case 5: aRes[ clock++ ] =(aRes[ref++]);
          case 4: aRes[ clock++ ] =(aRes[ref++]);
          case 3: aRes[ clock++ ] =(aRes[ref++]);
          case 2: aRes[ clock++ ] =(aRes[ref++]);
          case 1: aRes[ clock++ ] =(aRes[ref++]);
          case 0: aRes[ clock++ ] =(aRes[ref++]); // two octets more
              aRes[ clock++ ] =(aRes[ref++]);
        }
      }
    } while( ip < iEnd );
        
    return new Buffer(aRes).toString(); //returning a buffer
  },
  
  /**
  * @return Buffer compressed data
  *
  * @param  string or buffer the data we want to compress
  **/
  compress  : function( inputString ) {
    var sD;

    sD = Buffer.isBuffer(inputString) ? inputString : new Buffer(inputString);

    var       
      htab = [],
      iEnd = sD.length,
      aRes = [],
      ip = 0,
      op = 1,
      lit = 0,
      hval,
      hslot,
      ref,
      off,
      len,
      maxlen;
    
    hval = _FRST( ip, sD );
    
    while( ip < iEnd - 2 ) {
      hval = _NEXT( hval, ip, sD );
      hslot = _IDX( hval );
      ref = htab[ hslot ] ? htab[ hslot ] : 0;
      htab[ hslot ] = ip;
    
      if( ref < ip
        &&( off = ip - ref - 1 ) < _MAX_OFF
        && ip + 4 < iEnd
        && ref > 0
        && sD[ ref ]    === sD[ ip ]
        && sD[ ref + 1 ]  === sD[ ip + 1 ]
        && sD[ ref + 2 ]  === sD[ ip + 2 ]
      )
      {
        len = 2;
        maxlen = iEnd - ip - len;
        maxlen = maxlen > _MAX_REF ? _MAX_REF : maxlen;
        if( lit > 0 )
          aRes[ op - lit - 1 ] = ( lit - 1 ) & 255;
        else
          --op;
          
        for(;;) {
          if( maxlen > 16 ) {
            ++len; if( sD[ ref + len ] != sD[ ip + len ] )  break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] )  break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] )  break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] )  break;

            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;

            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;

            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
            ++len; if( sD[ ref + len ] != sD[ ip + len ] ) break;
          }
          do len++; while( len < maxlen && sD[ ref + len ] == sD[ ip + len ] );
          break;
        }
        
        len -= 2;
        ++ip;
        
        if( len < 7 )
          aRes[ op++ ] = ( ( off >> 8 ) + ( len << 5 ) ) & 255;
        else {
          aRes[ op++ ] = ( ( off >> 8 ) +( 7 << 5 ) ) & 255;
          aRes[ op++ ] = ( len - 7 ) & 255;
        }
        
        aRes[ op++ ] = ( off ) & 255;
        lit = 0;
        ++op;
        ip += len + 1;
        
        if( ip >= iEnd - 2 )
          break;
        
        --ip;
        
        hval = _FRST( ip, sD );
        hval = _NEXT( hval, ip, sD );
        htab[ _IDX( hval ) ] = ip++;
      } else {
        ++lit;
      
        aRes[ op++ ] = ( sD[ ip++ ] ) & 255;
        if( lit === _MAX_LIT ) {
          aRes[ op - lit - 1 ] = ( lit - 1 ) & 255;
          lit = 0; 
          ++op;
        }
      }
    }
    while( ip < iEnd ) {
      ++lit; 
      aRes[ op++ ] = ( sD[ ip++ ] ) & 255;
      if( lit === _MAX_LIT ) {
        aRes[ op - lit - 1 ] = ( lit - 1 ) & 255;
        lit = 0;
        ++op;
      }
    }
    sD = null;
    
    if( lit > 0 )
      aRes[ op - lit - 1 ] = ( lit - 1 ) & 255;
      
    var head = new Buffer(4)
    head.writeUInt32LE(iEnd, 0)
    
    return Buffer.concat([head, new Buffer(aRes)])
    //return new Buffer(aRes)
  }
}